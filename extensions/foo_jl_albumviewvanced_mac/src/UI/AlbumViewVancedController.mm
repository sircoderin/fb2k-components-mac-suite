#import "AlbumViewVancedController.h"
#import "AlbumGridView.h"
#import "../Core/AlbumDataSource.h"
#import "../Core/AlbumItem.h"
#import "../fb2k_sdk.h"
#import "../../../../shared/UIStyles.h"

static const CGFloat kSearchFieldHeight = 24.0;
static const CGFloat kStatusBarHeight   = 18.0;
static const CGFloat kSearchTopMargin   = 6.0;
static const CGFloat kSearchScrollGap   = 4.0;
static const CGFloat kStatusBottomMargin = 4.0;
static const CGFloat kPadding           = 8.0;

@interface AlbumViewVancedController () <NSSearchFieldDelegate, AlbumDataSourceDelegate, AlbumGridViewDelegate>
@end

@implementation AlbumViewVancedController {
    NSVisualEffectView *_containerView;
    NSSearchField      *_searchField;
    NSScrollView       *_scrollView;
    AlbumGridView      *_gridView;
    NSTextField        *_statusLabel;
    AlbumDataSource    *_dataSource;
    BOOL                _initialLoadDone;

    // Context menu state (must survive menu lifecycle)
    contextmenu_manager_v2::ptr _contextMenuManager;
    service_ptr_t<contextmenu_manager> _contextMenuManagerV1;
    metadb_handle_list _contextMenuHandles;

    // Debounced search
    NSTimer *_searchDebounceTimer;
    NSTimer *_libraryRebuildDebounceTimer;
}

- (void)loadView {
    _containerView = [[NSVisualEffectView alloc] initWithFrame:NSMakeRect(0, 0, 400, 500)];
    _containerView.material = NSVisualEffectMaterialSidebar;
    _containerView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    _containerView.state = NSVisualEffectStateActive;
    _containerView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.view = _containerView;

    [self setupSearchField];
    [self setupGridView];
    [self setupStatusBar];
    [self setupDataSource];
    [self layoutAllSubviews];
}

- (void)setupSearchField {
    _searchField = [[NSSearchField alloc] initWithFrame:NSZeroRect];
    _searchField.placeholderString = @"Search library...";
    _searchField.delegate = self;
    _searchField.sendsSearchStringImmediately = NO;
    _searchField.sendsWholeSearchString = YES;
    [_containerView addSubview:_searchField];
}

- (void)setupGridView {
    _scrollView = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    _scrollView.drawsBackground = NO;
    _scrollView.backgroundColor = [NSColor clearColor];
    _scrollView.hasVerticalScroller = YES;
    _scrollView.hasHorizontalScroller = NO;
    _scrollView.autohidesScrollers = YES;

    _gridView = [[AlbumGridView alloc] initWithFrame:NSZeroRect];
    _gridView.delegate = self;

    _scrollView.documentView = _gridView;
    [_containerView addSubview:_scrollView];
}

- (void)setupStatusBar {
    _statusLabel = [NSTextField labelWithString:@""];
    _statusLabel.font = fb2k_ui::statusBarFont();
    _statusLabel.textColor = fb2k_ui::secondaryTextColor();
    _statusLabel.frame = NSZeroRect;
    [_containerView addSubview:_statusLabel];
}

- (void)setupDataSource {
    _dataSource = [[AlbumDataSource alloc] init];
    _dataSource.delegate = self;
}

- (void)viewDidAppear {
    [super viewDidAppear];
    if (!_initialLoadDone) {
        _initialLoadDone = YES;
        [self scheduleLibraryRebuild];
    }
}

#pragma mark - Layout (frame-based)

- (void)viewDidLayout {
    [super viewDidLayout];
    [self layoutAllSubviews];
}

- (void)layoutAllSubviews {
    NSRect bounds = _containerView.bounds;
    CGFloat w = bounds.size.width;
    CGFloat h = bounds.size.height;

    CGFloat searchY = h - kSearchTopMargin - kSearchFieldHeight;
    _searchField.frame = NSMakeRect(kPadding, searchY, w - kPadding * 2, kSearchFieldHeight);

    CGFloat statusY = kStatusBottomMargin;
    _statusLabel.frame = NSMakeRect(kPadding, statusY, w - kPadding * 2, kStatusBarHeight);

    CGFloat scrollBottom = statusY + kStatusBarHeight;
    CGFloat scrollTop = searchY - kSearchScrollGap;
    CGFloat scrollHeight = scrollTop - scrollBottom;
    if (scrollHeight < 0) scrollHeight = 0;
    _scrollView.frame = NSMakeRect(0, scrollBottom, w, scrollHeight);

    // Update grid view width and recalc content height
    NSRect gridFrame = _gridView.frame;
    gridFrame.size.width = w;
    _gridView.frame = gridFrame;
    [_gridView recalcFrameHeight];
}

#pragma mark - AlbumDataSourceDelegate

- (void)albumDataSourceDidBeginUpdate {
    _statusLabel.stringValue = @"Loading...";
}

- (void)albumDataSourceDidUpdate {
    _gridView.albums = _dataSource.albums;
    [_gridView reloadData];
    [self updateStatusText];
}

- (void)updateStatusText {
    NSUInteger albumCount = _dataSource.albums.count;
    NSUInteger trackCount = _dataSource.totalTrackCount;
    _statusLabel.stringValue = [NSString stringWithFormat:@"%lu %@, %lu %@",
                                (unsigned long)albumCount,
                                albumCount == 1 ? @"album" : @"albums",
                                (unsigned long)trackCount,
                                trackCount == 1 ? @"track" : @"tracks"];
}

#pragma mark - NSSearchFieldDelegate

- (void)controlTextDidChange:(NSNotification *)obj {
    [_searchDebounceTimer invalidate];
    _searchDebounceTimer = [NSTimer scheduledTimerWithTimeInterval:0.3
                                                           target:self
                                                         selector:@selector(debouncedSearch)
                                                         userInfo:nil
                                                          repeats:NO];
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView
    doCommandBySelector:(SEL)commandSelector {
    if (commandSelector == @selector(insertNewline:)) {
        [_searchDebounceTimer invalidate];
        [self performSearch];
        return YES;
    }
    if (commandSelector == @selector(cancelOperation:)) {
        [_searchDebounceTimer invalidate];
        _searchField.stringValue = @"";
        [self performSearch];
        return YES;
    }
    return NO;
}

- (void)debouncedSearch {
    [self performSearch];
}

- (void)performSearch {
    NSString *query = _searchField.stringValue;
    if (query.length == 0) query = nil;
    [_gridView collapseExpandedAlbum];
    [_dataSource rebuildWithFilter:query];
}

- (void)scheduleLibraryRebuild {
    [_libraryRebuildDebounceTimer invalidate];
    _libraryRebuildDebounceTimer = [NSTimer scheduledTimerWithTimeInterval:0.12
                                                                     target:self
                                                                   selector:@selector(executeLibraryRebuild)
                                                                   userInfo:nil
                                                                    repeats:NO];
}

- (void)executeLibraryRebuild {
    NSString *query = _searchField.stringValue;
    if (query.length == 0) query = nil;
    [_dataSource rebuildWithFilter:query];
}

#pragma mark - AlbumGridViewDelegate

- (void)albumGridView:(id)gridView wantsPlayAlbum:(AlbumItem *)album {
    [self playPaths:[album allTrackPaths] startIndex:0];
}

- (void)albumGridView:(id)gridView wantsPlayTrack:(AlbumTrack *)track inAlbum:(AlbumItem *)album {
    NSArray *paths = [album allTrackPaths];
    NSUInteger idx = [paths indexOfObject:track.path];
    [self playPaths:paths startIndex:(idx != NSNotFound) ? idx : 0];
}

- (void)albumGridView:(id)gridView wantsQueueAlbum:(AlbumItem *)album {
    [self queuePathsDirectly:[album allTrackPaths]];
}

- (void)albumGridView:(id)gridView wantsQueueTrack:(AlbumTrack *)track inAlbum:(AlbumItem *)album {
    [self queuePathsDirectly:@[track.path]];
}

- (void)albumGridView:(id)gridView requestsContextMenuForAlbum:(AlbumItem *)album atPoint:(NSPoint)screenPoint {
    [self showContextMenuForPaths:[album allTrackPaths] atScreenPoint:screenPoint];
}

- (void)albumGridView:(id)gridView requestsContextMenuForTrack:(AlbumTrack *)track
               inAlbum:(AlbumItem *)album atPoint:(NSPoint)screenPoint {
    [self showContextMenuForPaths:@[track.path] atScreenPoint:screenPoint];
}

#pragma mark - Playback actions

/// Flush the playback queue, add all tracks, and start playing from startIndex
- (void)playPaths:(NSArray<NSString *> *)paths startIndex:(NSUInteger)startIndex {
    if (paths.count == 0) return;

    try {
        auto plMgr = playlist_manager::get();
        auto pbCtrl = playback_control::get();

        metadb_handle_list items;
        auto db = metadb::get();
        for (NSString *path in paths) {
            auto handle = db->handle_create([path UTF8String], 0);
            if (handle.is_valid()) items.add_item(handle);
        }
        if (items.get_count() == 0) return;
        if (startIndex >= items.get_count()) startIndex = 0;

        // Flush queue, add tracks starting from the requested index
        plMgr->queue_flush();
        for (t_size i = startIndex; i < items.get_count(); i++) {
            plMgr->queue_add_item(items[i]);
        }
        for (t_size i = 0; i < startIndex; i++) {
            plMgr->queue_add_item(items[i]);
        }

        pbCtrl->start(playback_control::track_command_play);
    } catch (...) {
        FB2K_console_formatter() << "[AlbumViewVanced] Error starting playback";
    }
}

- (void)addPathsToQueue:(NSArray<NSString *> *)paths {
    if (paths.count == 0) return;

    try {
        auto plMgr = playlist_manager::get();
        auto pbCtrl = playback_control::get();

        t_size active = plMgr->get_active_playlist();
        if (active == pfc::infinite_size) {
            active = plMgr->create_playlist_autoname(0);
            plMgr->set_active_playlist(active);
        }

        metadb_handle_list items;
        auto db = metadb::get();
        for (NSString *path in paths) {
            auto handle = db->handle_create([path UTF8String], 0);
            if (handle.is_valid()) items.add_item(handle);
        }

        if (items.get_count() == 0) return;

        // Add to active playlist first
        t_size baseIndex = plMgr->playlist_get_item_count(active);
        plMgr->playlist_add_items(active, items, bit_array_false());

        // Queue each added item
        bool queueWasEmpty = (plMgr->queue_get_count() == 0);
        for (t_size i = 0; i < items.get_count(); i++) {
            plMgr->queue_add_item_playlist(active, baseIndex + i);
        }

        // Auto-start playback if queue was empty and not playing
        if (queueWasEmpty && !pbCtrl->is_playing()) {
            pbCtrl->start(playback_control::track_command_play);
        }
    } catch (...) {
        FB2K_console_formatter() << "[AlbumViewVanced] Error adding tracks to queue";
    }
}

/// Queue paths directly without adding them to any playlist.
- (void)queuePathsDirectly:(NSArray<NSString *> *)paths {
    if (paths.count == 0) return;
    try {
        auto plMgr = playlist_manager::get();
        auto pbCtrl = playback_control::get();
        auto db = metadb::get();
        bool queueWasEmpty = (plMgr->queue_get_count() == 0);
        for (NSString *path in paths) {
            auto handle = db->handle_create([path UTF8String], 0);
            if (handle.is_valid()) plMgr->queue_add_item(handle);
        }
        if (queueWasEmpty && !pbCtrl->is_playing()) {
            pbCtrl->start(playback_control::track_command_play);
        }
    } catch (...) {
        FB2K_console_formatter() << "[AlbumViewVanced] Error queuing tracks";
    }
}

- (void)showContextMenuForPaths:(NSArray<NSString *> *)paths atScreenPoint:(NSPoint)screenPoint {
    if (paths.count == 0) return;

    @try {
        _contextMenuManager.release();
        _contextMenuManagerV1.release();

        metadb_handle_list items;
        auto db = metadb::get();
        for (NSString *path in paths) {
            auto handle = db->handle_create([path UTF8String], 0);
            if (handle.is_valid()) items.add_item(handle);
        }
        if (items.get_count() == 0) return;
        _contextMenuHandles = items;

        NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
        [menu setAutoenablesItems:NO];

        NSMenuItem *playItem = [[NSMenuItem alloc]
            initWithTitle:@"Play"
                   action:@selector(contextPlay:)
            keyEquivalent:@"\r"];
        playItem.target = self;
        playItem.representedObject = paths;
        [menu addItem:playItem];

        NSMenuItem *addToQueueItem = [[NSMenuItem alloc]
            initWithTitle:@"Add to Playback Queue"
                   action:@selector(contextAddToQueue:)
            keyEquivalent:@"q"];
        addToQueueItem.target = self;
        addToQueueItem.representedObject = paths;
        [menu addItem:addToQueueItem];

        [menu addItem:[NSMenuItem separatorItem]];

        // foobar2000 SDK context menu (v2 preferred)
        auto cmm = contextmenu_manager_v2::tryGet();
        if (cmm.is_valid()) {
            _contextMenuManager = cmm;
            _contextMenuManager->init_context(items, 0);
            menu_tree_item::ptr root = _contextMenuManager->build_menu();
            if (root.is_valid()) {
                [self buildNSMenu:menu fromMenuItem:root contextManager:_contextMenuManager];
            }
        } else {
            _contextMenuManagerV1 = contextmenu_manager::g_create();
            _contextMenuManagerV1->init_context(items, 0);
        }

        [menu popUpMenuPositioningItem:nil atLocation:screenPoint inView:nil];

    } @catch (NSException *exception) {
        FB2K_console_formatter() << "[AlbumViewVanced] Context menu error: "
            << [[exception description] UTF8String];
    }
}

- (void)buildNSMenu:(NSMenu *)menu
        fromMenuItem:(menu_tree_item::ptr)item
      contextManager:(contextmenu_manager_v2::ptr)manager {
    if (!item.is_valid()) return;

    size_t count = item->childCount();
    for (size_t i = 0; i < count; i++) {
        menu_tree_item::ptr child = item->childAt(i);
        if (!child.is_valid()) continue;

        if (child->isSeparator()) {
            [menu addItem:[NSMenuItem separatorItem]];
        } else if (child->isCommand()) {
            const char *itemName = child->name();
            NSString *title = itemName ? [NSString stringWithUTF8String:itemName] : @"";
            NSMenuItem *menuItem = [[NSMenuItem alloc]
                initWithTitle:title
                       action:@selector(contextMenuItemClicked:)
                keyEquivalent:@""];
            menuItem.target = self;
            menuItem.tag = (NSInteger)child->commandID();
            menuItem.enabled = !(child->flags() & menu_flags::disabled);
            [menu addItem:menuItem];
        } else if (child->isSubmenu()) {
            const char *itemName = child->name();
            NSString *title = itemName ? [NSString stringWithUTF8String:itemName] : @"";
            NSMenuItem *submenuItem = [[NSMenuItem alloc]
                initWithTitle:title action:nil keyEquivalent:@""];
            NSMenu *submenu = [[NSMenu alloc] initWithTitle:title];
            [self buildNSMenu:submenu fromMenuItem:child contextManager:manager];
            submenuItem.submenu = submenu;
            [menu addItem:submenuItem];
        }
    }
}

- (void)contextMenuItemClicked:(NSMenuItem *)sender {
    if (_contextMenuManager.is_valid()) {
        try {
            _contextMenuManager->execute_by_id((unsigned)sender.tag);
        } catch (...) {
            FB2K_console_formatter() << "[AlbumViewVanced] Context menu execution error";
        }
    }
}

- (void)contextPlay:(NSMenuItem *)sender {
    NSArray<NSString *> *paths = sender.representedObject;
    [self playPaths:paths startIndex:0];
}

- (void)contextAddToQueue:(NSMenuItem *)sender {
    NSArray<NSString *> *paths = sender.representedObject;
    [self addPathsToQueue:paths];
}

#pragma mark - Library callbacks

- (void)handleLibraryItemsAdded {
    [self scheduleLibraryRebuild];
}

- (void)handleLibraryItemsRemoved {
    [self scheduleLibraryRebuild];
}

- (void)handleLibraryItemsModified {
    [self scheduleLibraryRebuild];
}

- (void)dealloc {
    [_searchDebounceTimer invalidate];
    [_libraryRebuildDebounceTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
