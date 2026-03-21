#import "NowPlayingView.h"
#import "../Core/TrackInfo.h"
#import "../Core/ArtworkFetcher.h"
#import "../../../../shared/UIStyles.h"

static const CGFloat kBarHeight       = 52.0;
static const CGFloat kArtSize         = 40.0;
static const CGFloat kPadding         = 6.0;
static const CGFloat kButtonSize      = 28.0;
static const CGFloat kSmallButtonSize = 22.0;
static const CGFloat kButtonSpacing   = 2.0;
static const CGFloat kProgressHeight  = 4.0;
static const CGFloat kVolumeWidth     = 70.0;

static NSPasteboardType const kSimPlaylistPBType = @"com.foobar2000.simplaylist.rows";

@interface NowPlayingView ()
@property (nonatomic, strong) NSImageView *artworkView;
@property (nonatomic, strong) NSTextField *titleLabel;
@property (nonatomic, strong) NSTextField *artistLabel;
@property (nonatomic, strong) NSButton *prevButton;
@property (nonatomic, strong) NSButton *playPauseButton;
@property (nonatomic, strong) NSButton *nextButton;
@property (nonatomic, strong) NSSlider *progressSlider;
@property (nonatomic, strong) NSTextField *elapsedLabel;
@property (nonatomic, strong) NSTextField *remainingLabel;
@property (nonatomic, strong) NSSlider *volumeSlider;
@property (nonatomic, strong) NSTextField *idleLabel;
@property (nonatomic, assign) BOOL isSeeking;
@property (nonatomic, assign) BOOL isDragTarget;
@end

@implementation NowPlayingView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        _playbackPosition = 0;
        _trackDuration = 0;
        _isPlaying = NO;
        _isPaused = NO;
        _volume = 1.0;
        _isSeeking = NO;
        [self setupSubviews];
    }
    return self;
}

- (BOOL)isFlipped {
    return YES;
}

#pragma mark - Setup

- (void)setupSubviews {
    // Album art
    _artworkView = [[NSImageView alloc] init];
    _artworkView.imageScaling = NSImageScaleProportionallyUpOrDown;
    _artworkView.translatesAutoresizingMaskIntoConstraints = NO;
    _artworkView.wantsLayer = YES;
    _artworkView.layer.cornerRadius = 4.0;
    _artworkView.layer.masksToBounds = YES;
    [self addSubview:_artworkView];

    // Title
    _titleLabel = [self makeLabel];
    _titleLabel.font = [NSFont systemFontOfSize:12.0 weight:NSFontWeightSemibold];
    _titleLabel.textColor = fb2k_ui::textColor();
    [self addSubview:_titleLabel];

    // Artist
    _artistLabel = [self makeLabel];
    _artistLabel.font = [NSFont systemFontOfSize:11.0 weight:NSFontWeightRegular];
    _artistLabel.textColor = fb2k_ui::secondaryTextColor();
    [self addSubview:_artistLabel];

    // Transport buttons
    _prevButton = [self makeTransportButton:@"backward.fill" size:kSmallButtonSize action:@selector(prevPressed:)];
    [self addSubview:_prevButton];

    _playPauseButton = [self makeTransportButton:@"play.fill" size:kButtonSize action:@selector(playPausePressed:)];
    [self addSubview:_playPauseButton];

    _nextButton = [self makeTransportButton:@"forward.fill" size:kSmallButtonSize action:@selector(nextPressed:)];
    [self addSubview:_nextButton];

    // Progress slider
    _progressSlider = [[NSSlider alloc] init];
    _progressSlider.translatesAutoresizingMaskIntoConstraints = NO;
    _progressSlider.minValue = 0.0;
    _progressSlider.maxValue = 1.0;
    _progressSlider.doubleValue = 0.0;
    _progressSlider.target = self;
    _progressSlider.action = @selector(progressChanged:);
    _progressSlider.continuous = YES;
    [self addSubview:_progressSlider];

    // Elapsed time
    _elapsedLabel = [self makeTimeLabel];
    [self addSubview:_elapsedLabel];

    // Remaining time
    _remainingLabel = [self makeTimeLabel];
    _remainingLabel.alignment = NSTextAlignmentRight;
    [self addSubview:_remainingLabel];

    // Volume slider
    _volumeSlider = [[NSSlider alloc] init];
    _volumeSlider.translatesAutoresizingMaskIntoConstraints = NO;
    _volumeSlider.minValue = 0.0;
    _volumeSlider.maxValue = 1.0;
    _volumeSlider.doubleValue = 1.0;
    _volumeSlider.target = self;
    _volumeSlider.action = @selector(volumeChanged:);
    _volumeSlider.continuous = YES;
    [self addSubview:_volumeSlider];

    // Idle label
    _idleLabel = [self makeLabel];
    _idleLabel.font = [NSFont systemFontOfSize:12.0 weight:NSFontWeightLight];
    _idleLabel.textColor = [fb2k_ui::secondaryTextColor() colorWithAlphaComponent:0.5];
    _idleLabel.stringValue = @"Not playing";
    _idleLabel.alignment = NSTextAlignmentCenter;
    [self addSubview:_idleLabel];

    [self registerForDraggedTypes:@[kSimPlaylistPBType, NSPasteboardTypeFileURL]];
}

- (NSTextField *)makeLabel {
    NSTextField *label = [[NSTextField alloc] init];
    label.bordered = NO;
    label.editable = NO;
    label.selectable = NO;
    label.drawsBackground = NO;
    label.lineBreakMode = NSLineBreakByTruncatingTail;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.cell.truncatesLastVisibleLine = YES;
    return label;
}

- (NSTextField *)makeTimeLabel {
    NSTextField *label = [self makeLabel];
    label.font = [NSFont monospacedDigitSystemFontOfSize:10.0 weight:NSFontWeightRegular];
    label.textColor = fb2k_ui::secondaryTextColor();
    label.stringValue = @"0:00";
    return label;
}

- (NSButton *)makeTransportButton:(NSString *)symbolName size:(CGFloat)size action:(SEL)action {
    NSButton *button = [[NSButton alloc] init];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.bordered = NO;
    button.bezelStyle = NSBezelStyleRegularSquare;
    button.target = self;
    button.action = action;

    NSImageSymbolConfiguration *config = [NSImageSymbolConfiguration
        configurationWithPointSize:(size == kButtonSize ? 16 : 12)
        weight:NSFontWeightMedium
        scale:NSImageSymbolScaleMedium];

    NSImage *img = [[NSImage imageWithSystemSymbolName:symbolName
                                      accessibilityDescription:symbolName]
                    imageWithSymbolConfiguration:config];
    button.image = img;
    button.imagePosition = NSImageOnly;
    button.contentTintColor = fb2k_ui::textColor();

    [NSLayoutConstraint activateConstraints:@[
        [button.widthAnchor constraintEqualToConstant:size],
        [button.heightAnchor constraintEqualToConstant:size],
    ]];

    return button;
}

#pragma mark - Layout

- (void)layout {
    [super layout];

    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    CGFloat midY = h / 2.0;

    BOOL hasTrack = self.isPlaying || self.isPaused || self.trackInfo != nil;

    _idleLabel.hidden = hasTrack;
    _artworkView.hidden = !hasTrack;
    _titleLabel.hidden = !hasTrack;
    _artistLabel.hidden = !hasTrack;
    _prevButton.hidden = !hasTrack;
    _playPauseButton.hidden = !hasTrack;
    _nextButton.hidden = !hasTrack;
    _progressSlider.hidden = !hasTrack;
    _elapsedLabel.hidden = !hasTrack;
    _remainingLabel.hidden = !hasTrack;
    _volumeSlider.hidden = !hasTrack;

    if (!hasTrack) {
        _idleLabel.frame = NSMakeRect(0, midY - 8, w, 16);
        return;
    }

    CGFloat x = kPadding;

    // Album art
    CGFloat artY = (h - kArtSize) / 2.0;
    _artworkView.frame = NSMakeRect(x, artY, kArtSize, kArtSize);
    x += kArtSize + kPadding;

    // Text info section (artist / title) — fixed width
    CGFloat textWidth = 140.0;
    if (w < 700) textWidth = 100.0;
    if (w < 500) textWidth = 80.0;

    _titleLabel.frame = NSMakeRect(x, midY - 18, textWidth, 16);
    _artistLabel.frame = NSMakeRect(x, midY + 2, textWidth, 14);
    x += textWidth + kPadding;

    // Transport buttons
    CGFloat btnGroupWidth = kSmallButtonSize + kButtonSpacing + kButtonSize + kButtonSpacing + kSmallButtonSize;
    CGFloat btnX = x;
    CGFloat btnY = midY - kButtonSize / 2.0;
    CGFloat smallBtnY = midY - kSmallButtonSize / 2.0;

    _prevButton.frame = NSMakeRect(btnX, smallBtnY, kSmallButtonSize, kSmallButtonSize);
    btnX += kSmallButtonSize + kButtonSpacing;
    _playPauseButton.frame = NSMakeRect(btnX, btnY, kButtonSize, kButtonSize);
    btnX += kButtonSize + kButtonSpacing;
    _nextButton.frame = NSMakeRect(btnX, smallBtnY, kSmallButtonSize, kSmallButtonSize);
    x += btnGroupWidth + kPadding * 2;

    // Volume slider (from right edge)
    CGFloat volumeX = w - kPadding - kVolumeWidth;
    _volumeSlider.frame = NSMakeRect(volumeX, midY - 10, kVolumeWidth, 20);

    // Progress area fills the remaining space
    CGFloat timeWidth = 38.0;
    CGFloat progressRight = volumeX - kPadding;
    CGFloat progressLeft = x;

    _elapsedLabel.frame = NSMakeRect(progressLeft, midY - 16, timeWidth, 14);
    _remainingLabel.frame = NSMakeRect(progressRight - timeWidth, midY - 16, timeWidth, 14);

    CGFloat sliderLeft = progressLeft + timeWidth + 4;
    CGFloat sliderRight = progressRight - timeWidth - 4;
    CGFloat sliderWidth = sliderRight - sliderLeft;
    if (sliderWidth < 40) sliderWidth = 40;
    _progressSlider.frame = NSMakeRect(sliderLeft, midY - 10, sliderWidth, 20);

    // Elapsed/remaining below slider for narrow widths? No, keep inline.
    // Update time labels position to be below the slider for cleaner look
    _elapsedLabel.frame = NSMakeRect(sliderLeft, midY + 6, timeWidth + 10, 14);
    _remainingLabel.frame = NSMakeRect(sliderLeft + sliderWidth - timeWidth - 10, midY + 6, timeWidth + 10, 14);
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    if (_isDragTarget) {
        [[NSColor controlAccentColor] setStroke];
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(self.bounds, 2, 2)
                                                            xRadius:4 yRadius:4];
        path.lineWidth = 3.0;
        [path stroke];
    }
}

#pragma mark - Drag Destination

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    NSPasteboard *pb = [sender draggingPasteboard];
    if ([pb.types containsObject:kSimPlaylistPBType] ||
        [pb.types containsObject:NSPasteboardTypeFileURL]) {
        self.isDragTarget = YES;
        [self setNeedsDisplay:YES];
        return NSDragOperationCopy;
    }
    return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender {
    return _isDragTarget ? NSDragOperationCopy : NSDragOperationNone;
}

- (void)draggingExited:(nullable id<NSDraggingInfo>)sender {
    self.isDragTarget = NO;
    [self setNeedsDisplay:YES];
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {
    return YES;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    self.isDragTarget = NO;
    [self setNeedsDisplay:YES];

    NSPasteboard *pb = [sender draggingPasteboard];
    NSMutableArray<NSString *> *paths = [NSMutableArray array];

    // Prefer SimPlaylist internal type (carries foobar2000 paths)
    if ([pb.types containsObject:kSimPlaylistPBType]) {
        NSData *data = [pb dataForType:kSimPlaylistPBType];
        if (data) {
            NSDictionary *dragData = [NSKeyedUnarchiver
                unarchivedObjectOfClasses:[NSSet setWithObjects:
                    [NSDictionary class], [NSArray class],
                    [NSNumber class], [NSString class], nil]
                fromData:data error:nil];
            NSArray<NSString *> *dragPaths = dragData[@"paths"];
            if (dragPaths) [paths addObjectsFromArray:dragPaths];
        }
    }

    // Fallback to standard file URLs
    if (paths.count == 0 && [pb.types containsObject:NSPasteboardTypeFileURL]) {
        NSArray *urls = [pb readObjectsForClasses:@[[NSURL class]]
                                          options:@{NSPasteboardURLReadingFileURLsOnlyKey: @YES}];
        for (NSURL *url in urls) {
            if (url.path) [paths addObject:url.path];
        }
    }

    if (paths.count > 0 && [self.delegate respondsToSelector:@selector(nowPlayingViewDidReceiveDroppedPaths:)]) {
        [self.delegate nowPlayingViewDidReceiveDroppedPaths:paths];
        return YES;
    }
    return NO;
}

- (void)concludeDragOperation:(nullable id<NSDraggingInfo>)sender {
    self.isDragTarget = NO;
    [self setNeedsDisplay:YES];
}

#pragma mark - Actions

- (void)prevPressed:(id)sender {
    [self.delegate nowPlayingViewDidPressPrevious];
}

- (void)playPausePressed:(id)sender {
    [self.delegate nowPlayingViewDidPressPlayPause];
}

- (void)nextPressed:(id)sender {
    [self.delegate nowPlayingViewDidPressNext];
}

- (void)progressChanged:(id)sender {
    double fraction = _progressSlider.doubleValue;
    [self.delegate nowPlayingViewDidSeekToPosition:fraction];
}

- (void)volumeChanged:(id)sender {
    float vol = (float)_volumeSlider.doubleValue;
    [self.delegate nowPlayingViewDidChangeVolume:vol];
}

#pragma mark - Property Setters

- (void)setArtworkImage:(NSImage *)artworkImage {
    _artworkImage = artworkImage;
    _artworkView.image = artworkImage ?: [ArtworkFetcher placeholderImageOfSize:kArtSize];
}

- (void)setTrackInfo:(TrackInfo *)trackInfo {
    _trackInfo = trackInfo;
    if (trackInfo) {
        _titleLabel.stringValue = trackInfo.title ?: @"";
        _artistLabel.stringValue = trackInfo.artist ?: @"";
    } else {
        _titleLabel.stringValue = @"";
        _artistLabel.stringValue = @"";
    }
    [self setNeedsLayout:YES];
}

- (void)setPlaybackPosition:(double)playbackPosition {
    _playbackPosition = playbackPosition;
    if (!_isSeeking && _trackDuration > 0) {
        _progressSlider.doubleValue = playbackPosition / _trackDuration;
    }
    _elapsedLabel.stringValue = [self formatTime:playbackPosition];
    _remainingLabel.stringValue = [self formatTime:_trackDuration];
}

- (void)setIsPlaying:(BOOL)isPlaying {
    _isPlaying = isPlaying;
    [self updatePlayPauseIcon];
    [self setNeedsLayout:YES];
}

- (void)setIsPaused:(BOOL)isPaused {
    _isPaused = isPaused;
    [self updatePlayPauseIcon];
}

- (void)setVolume:(float)volume {
    _volume = volume;
    _volumeSlider.doubleValue = volume;
}

- (void)updatePlayPauseIcon {
    NSString *symbol = (_isPlaying && !_isPaused) ? @"pause.fill" : @"play.fill";
    NSImageSymbolConfiguration *config = [NSImageSymbolConfiguration
        configurationWithPointSize:16
        weight:NSFontWeightMedium
        scale:NSImageSymbolScaleMedium];
    _playPauseButton.image = [[NSImage imageWithSystemSymbolName:symbol
                                                accessibilityDescription:symbol]
                              imageWithSymbolConfiguration:config];
}

- (void)clearDisplay {
    _artworkImage = nil;
    _trackInfo = nil;
    _playbackPosition = 0;
    _trackDuration = 0;
    _isPlaying = NO;
    _isPaused = NO;
    _artworkView.image = nil;
    _titleLabel.stringValue = @"";
    _artistLabel.stringValue = @"";
    _progressSlider.doubleValue = 0;
    _elapsedLabel.stringValue = @"0:00";
    _remainingLabel.stringValue = @"0:00";
    [self updatePlayPauseIcon];
    [self setNeedsLayout:YES];
}

#pragma mark - Time Formatting

- (NSString *)formatTime:(double)seconds {
    if (seconds < 0 || !isfinite(seconds)) return @"0:00";
    int totalSeconds = (int)seconds;
    int minutes = totalSeconds / 60;
    int secs = totalSeconds % 60;
    return [NSString stringWithFormat:@"%d:%02d", minutes, secs];
}

@end
