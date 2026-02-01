//
//  ScrobbleWidgetView.mm
//  foo_jl_scrobble_mac
//
//  Custom NSView for displaying Last.fm stats widget
//

#import "ScrobbleWidgetView.h"
#import "../Core/TopAlbum.h"
#import <QuartzCore/QuartzCore.h>

static const CGFloat kArrowWidth = 32.0;
static const CGFloat kMinAlbumSize = 64.0;
static const CGFloat kMaxAlbumSize = 150.0;
static const CGFloat kAlbumSpacing = 6.0;
static const CGFloat kProfileHeight = 40.0;
static const CGFloat kFooterHeight = 20.0;
static const CGFloat kPadding = 8.0;
static const NSTimeInterval kArrowFadeDuration = 0.15;

@interface ScrobbleWidgetView ()
@property (nonatomic, strong) NSTrackingArea *trackingArea;
@property (nonatomic, assign) BOOL isHovered;
@property (nonatomic, assign) CGFloat arrowOpacity;
@property (nonatomic, assign) CGFloat calculatedAlbumSize;
@property (nonatomic, assign) NSInteger hoveredAlbumIndex;  // -1 if none
@property (nonatomic, strong) NSMutableArray<NSValue *> *albumRects;  // Store album rects for hit testing
@property (nonatomic, assign) NSRect profileLinkRect;  // Last.fm link button rect
@property (nonatomic, assign) BOOL isOverProfileLink;
// Period/Type dropdown pill rects
@property (nonatomic, assign) NSRect periodPillRect;
@property (nonatomic, assign) BOOL isOverPeriodPill;
@property (nonatomic, assign) NSRect typePillRect;
@property (nonatomic, assign) BOOL isOverTypePill;
// Reload button
@property (nonatomic, assign) NSRect reloadButtonRect;
@property (nonatomic, assign) BOOL isOverReloadButton;
// Animation state
@property (nonatomic, assign) BOOL isAnimatingTransition;
// Glass effect
@property (nonatomic, strong, nullable) NSVisualEffectView *glassEffectView;
@end

@implementation ScrobbleWidgetView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _state = ScrobbleWidgetStateLoading;
        _maxAlbums = 10;  // Default, will be updated by controller from config
        _scrobbledToday = 0;
        _queueCount = 0;
        _arrowOpacity = 0.0;
        _currentPeriod = ScrobbleChartPeriodWeekly;
        _currentType = ScrobbleChartTypeAlbums;
        _periodTitle = [ScrobbleWidgetView titleForPeriod:_currentPeriod];
        _typeTitle = [ScrobbleWidgetView titleForType:_currentType];
        _hoveredAlbumIndex = -1;
        _albumRects = [NSMutableArray array];
        self.wantsLayer = YES;

        // Use minimum priorities so the view doesn't resist being resized by the layout system
        [self setContentHuggingPriority:1 forOrientation:NSLayoutConstraintOrientationHorizontal];
        [self setContentHuggingPriority:1 forOrientation:NSLayoutConstraintOrientationVertical];
        [self setContentCompressionResistancePriority:1 forOrientation:NSLayoutConstraintOrientationHorizontal];
        [self setContentCompressionResistancePriority:1 forOrientation:NSLayoutConstraintOrientationVertical];

        [self setupTrackingArea];
    }
    return self;
}

// Don't constrain intrinsic size - let layout system decide
- (NSSize)intrinsicContentSize {
    // Intentionally returns no intrinsic size - let layout system decide
    return NSMakeSize(NSViewNoIntrinsicMetric, NSViewNoIntrinsicMetric);
}

// Override fittingSize to not constrain layout
- (NSSize)fittingSize {
    // Return current bounds - let layout system control sizing
    return self.bounds.size;
}

- (void)dealloc {
    if (_trackingArea) {
        [self removeTrackingArea:_trackingArea];
    }
}

#pragma mark - Legacy Property Accessors

- (ScrobbleChartPage)currentPage {
    return _currentPeriod;
}

- (void)setCurrentPage:(ScrobbleChartPage)currentPage {
    _currentPeriod = currentPage;
}

- (NSString *)chartTitle {
    return [NSString stringWithFormat:@"%@ %@", _periodTitle ?: @"", _typeTitle ?: @""];
}

- (void)setChartTitle:(NSString *)chartTitle {
    // Parse or ignore - use periodTitle and typeTitle instead
}

#pragma mark - Background Settings

- (void)setUseGlassBackground:(BOOL)useGlassBackground {
    if (_useGlassBackground == useGlassBackground) return;
    _useGlassBackground = useGlassBackground;

    if (useGlassBackground) {
        if (!_glassEffectView) {
            _glassEffectView = [[NSVisualEffectView alloc] initWithFrame:self.bounds];
            _glassEffectView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
            _glassEffectView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
            _glassEffectView.material = NSVisualEffectMaterialSidebar;
            _glassEffectView.state = NSVisualEffectStateActive;
        }
        [self addSubview:_glassEffectView positioned:NSWindowBelow relativeTo:nil];
    } else {
        [_glassEffectView removeFromSuperview];
    }
    [self setNeedsDisplay:YES];
}

#pragma mark - Class Methods

+ (NSString *)apiPeriodForPeriod:(ScrobbleChartPeriod)period {
    switch (period) {
        case ScrobbleChartPeriodWeekly:  return @"7day";
        case ScrobbleChartPeriodMonthly: return @"1month";
        case ScrobbleChartPeriodOverall: return @"overall";
        default: return @"7day";
    }
}

+ (NSString *)titleForPeriod:(ScrobbleChartPeriod)period {
    switch (period) {
        case ScrobbleChartPeriodWeekly:  return @"Weekly";
        case ScrobbleChartPeriodMonthly: return @"Monthly";
        case ScrobbleChartPeriodOverall: return @"All Time";
        default: return @"Weekly";
    }
}

+ (NSString *)titleForType:(ScrobbleChartType)type {
    switch (type) {
        case ScrobbleChartTypeAlbums:  return @"Albums";
        case ScrobbleChartTypeArtists: return @"Artists";
        case ScrobbleChartTypeTracks:  return @"Tracks";
        default: return @"Albums";
    }
}

// Legacy aliases
+ (NSString *)periodForPage:(ScrobbleChartPage)page {
    return [self apiPeriodForPeriod:page];
}

+ (NSString *)titleForPage:(ScrobbleChartPage)page {
    return [NSString stringWithFormat:@"%@ Top Albums", [self titleForPeriod:page]];
}

#pragma mark - Tracking Area

- (void)setupTrackingArea {
    if (_trackingArea) {
        [self removeTrackingArea:_trackingArea];
    }

    NSTrackingAreaOptions options = (NSTrackingMouseEnteredAndExited |
                                     NSTrackingMouseMoved |
                                     NSTrackingActiveAlways |
                                     NSTrackingInVisibleRect);

    _trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                 options:options
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea:_trackingArea];

    NSLog(@"[ScrobbleWidget] setupTrackingArea - bounds: %@, window: %@",
          NSStringFromRect(self.bounds), self.window ? @"YES" : @"NO");
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    [self setupTrackingArea];
}

#pragma mark - View Sizing

- (void)setFrameSize:(NSSize)newSize {
    NSSize oldSize = self.frame.size;
    [super setFrameSize:newSize];
    if (!NSEqualSizes(oldSize, newSize)) {
        NSLog(@"[ScrobbleWidget] setFrameSize: %@ -> %@", NSStringFromSize(oldSize), NSStringFromSize(newSize));
        [self setNeedsDisplay:YES];
    }
}

- (void)setBounds:(NSRect)bounds {
    NSRect oldBounds = self.bounds;
    [super setBounds:bounds];
    if (!NSEqualRects(oldBounds, bounds)) {
        NSLog(@"[ScrobbleWidget] setBounds: %@ -> %@", NSStringFromRect(oldBounds), NSStringFromRect(bounds));
        [self setNeedsDisplay:YES];
    }
}

- (void)setFrame:(NSRect)frame {
    NSRect oldFrame = self.frame;
    [super setFrame:frame];
    if (!NSEqualRects(oldFrame, frame)) {
        NSLog(@"[ScrobbleWidget] setFrame: %@ -> %@", NSStringFromRect(oldFrame), NSStringFromRect(frame));
        [self setNeedsDisplay:YES];
    }
}

- (void)layout {
    [super layout];
    [self setNeedsDisplay:YES];
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    [super resizeSubviewsWithOldSize:oldSize];
    [self setNeedsDisplay:YES];
}

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    if (self.window) {
        NSLog(@"[ScrobbleWidget] viewDidMoveToWindow - bounds: %@", NSStringFromRect(self.bounds));
        [self setupTrackingArea];
        [self setNeedsDisplay:YES];
    }
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event {
    return YES;
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

#pragma mark - Layout Calculation

- (CGFloat)calculateAlbumSizeForWidth:(CGFloat)availableWidth {
    // Calculate optimal album size to show 4-6 albums per row
    // Target: fit 5 albums ideally, but allow 4-6 based on width

    // Try different album counts per row and pick the one closest to target size
    CGFloat targetSize = 130.0;  // Preferred album size
    CGFloat bestSize = kMinAlbumSize;

    for (NSInteger albumsPerRow = 3; albumsPerRow <= 8; albumsPerRow++) {
        CGFloat totalSpacing = kAlbumSpacing * (albumsPerRow - 1);
        CGFloat size = (availableWidth - totalSpacing) / albumsPerRow;

        // Clamp to min/max
        size = MAX(kMinAlbumSize, MIN(kMaxAlbumSize, size));

        // Pick the size closest to target that's within bounds
        if (fabs(size - targetSize) < fabs(bestSize - targetSize)) {
            bestSize = size;
        }
    }

    return bestSize;
}

#pragma mark - Mouse Events

- (void)mouseEntered:(NSEvent *)event {
    _isHovered = YES;
    [self animateArrowOpacity:1.0];
}

- (void)mouseExited:(NSEvent *)event {
    _isHovered = NO;
    _hoveredAlbumIndex = -1;
    _isOverProfileLink = NO;
    _isOverPeriodPill = NO;
    _isOverTypePill = NO;
    [self animateArrowOpacity:0.0];
    [self setNeedsDisplay:YES];
}

- (void)mouseMoved:(NSEvent *)event {
    NSPoint location = [self convertPoint:event.locationInWindow fromView:nil];

    NSInteger oldHoveredAlbum = _hoveredAlbumIndex;
    BOOL wasOverProfileLink = _isOverProfileLink;
    BOOL wasOverPeriod = _isOverPeriodPill;
    BOOL wasOverType = _isOverTypePill;
    BOOL wasOverReload = _isOverReloadButton;

    // Check if over profile link button
    _isOverProfileLink = !NSIsEmptyRect(_profileLinkRect) && NSPointInRect(location, _profileLinkRect);

    // Check reload button
    _isOverReloadButton = !NSIsEmptyRect(_reloadButtonRect) && NSPointInRect(location, _reloadButtonRect);

    // Check period pill
    _isOverPeriodPill = !NSIsEmptyRect(_periodPillRect) && NSPointInRect(location, _periodPillRect);

    // Check type pill
    _isOverTypePill = !NSIsEmptyRect(_typePillRect) && NSPointInRect(location, _typePillRect);

    // Check which album is being hovered
    _hoveredAlbumIndex = -1;
    for (NSInteger i = 0; i < (NSInteger)_albumRects.count; i++) {
        NSRect rect = [_albumRects[i] rectValue];
        if (NSPointInRect(location, rect)) {
            _hoveredAlbumIndex = i;
            break;
        }
    }

    if (oldHoveredAlbum != _hoveredAlbumIndex || wasOverProfileLink != _isOverProfileLink ||
        wasOverPeriod != _isOverPeriodPill || wasOverType != _isOverTypePill ||
        wasOverReload != _isOverReloadButton) {
        [self setNeedsDisplay:YES];
    }
}

- (void)mouseDown:(NSEvent *)event {
    NSPoint location = [self convertPoint:event.locationInWindow fromView:nil];

    // Check if clicking on profile link
    if (!NSIsEmptyRect(_profileLinkRect) && NSPointInRect(location, _profileLinkRect)) {
        if ([_delegate respondsToSelector:@selector(widgetViewOpenLastFmProfile:)]) {
            [_delegate widgetViewOpenLastFmProfile:self];
        }
        return;
    }

    // Check if clicking on reload button
    if (!NSIsEmptyRect(_reloadButtonRect) && NSPointInRect(location, _reloadButtonRect)) {
        if ([_delegate respondsToSelector:@selector(widgetViewRequestsRefresh:)]) {
            [_delegate widgetViewRequestsRefresh:self];
        }
        return;
    }

    // Check period pill - show dropdown menu
    if (_isOverPeriodPill) {
        [self showPeriodMenu];
        return;
    }

    // Check type pill - show dropdown menu
    if (_isOverTypePill) {
        [self showTypeMenu];
        return;
    }

    // Check if clicking on an album
    for (NSInteger i = 0; i < (NSInteger)_albumRects.count; i++) {
        NSRect rect = [_albumRects[i] rectValue];
        if (NSPointInRect(location, rect)) {
            if ([_delegate respondsToSelector:@selector(widgetView:didClickAlbumAtIndex:)]) {
                [_delegate widgetView:self didClickAlbumAtIndex:i];
            }
            return;
        }
    }
}

- (void)showPeriodMenu {
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Period"];

    NSMenuItem *weeklyItem = [[NSMenuItem alloc] initWithTitle:@"Weekly" action:@selector(selectPeriodWeekly:) keyEquivalent:@""];
    weeklyItem.target = self;
    weeklyItem.state = (_currentPeriod == ScrobbleChartPeriodWeekly) ? NSControlStateValueOn : NSControlStateValueOff;
    [menu addItem:weeklyItem];

    NSMenuItem *monthlyItem = [[NSMenuItem alloc] initWithTitle:@"Monthly" action:@selector(selectPeriodMonthly:) keyEquivalent:@""];
    monthlyItem.target = self;
    monthlyItem.state = (_currentPeriod == ScrobbleChartPeriodMonthly) ? NSControlStateValueOn : NSControlStateValueOff;
    [menu addItem:monthlyItem];

    NSMenuItem *overallItem = [[NSMenuItem alloc] initWithTitle:@"All Time" action:@selector(selectPeriodOverall:) keyEquivalent:@""];
    overallItem.target = self;
    overallItem.state = (_currentPeriod == ScrobbleChartPeriodOverall) ? NSControlStateValueOn : NSControlStateValueOff;
    [menu addItem:overallItem];

    NSPoint menuPoint = NSMakePoint(_periodPillRect.origin.x, _periodPillRect.origin.y + _periodPillRect.size.height);
    [menu popUpMenuPositioningItem:nil atLocation:menuPoint inView:self];
}

- (void)showTypeMenu {
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Type"];

    NSMenuItem *albumsItem = [[NSMenuItem alloc] initWithTitle:@"Albums" action:@selector(selectTypeAlbums:) keyEquivalent:@""];
    albumsItem.target = self;
    albumsItem.state = (_currentType == ScrobbleChartTypeAlbums) ? NSControlStateValueOn : NSControlStateValueOff;
    [menu addItem:albumsItem];

    NSMenuItem *artistsItem = [[NSMenuItem alloc] initWithTitle:@"Artists" action:@selector(selectTypeArtists:) keyEquivalent:@""];
    artistsItem.target = self;
    artistsItem.state = (_currentType == ScrobbleChartTypeArtists) ? NSControlStateValueOn : NSControlStateValueOff;
    [menu addItem:artistsItem];

    NSMenuItem *tracksItem = [[NSMenuItem alloc] initWithTitle:@"Tracks" action:@selector(selectTypeTracks:) keyEquivalent:@""];
    tracksItem.target = self;
    tracksItem.state = (_currentType == ScrobbleChartTypeTracks) ? NSControlStateValueOn : NSControlStateValueOff;
    [menu addItem:tracksItem];

    NSPoint menuPoint = NSMakePoint(_typePillRect.origin.x, _typePillRect.origin.y + _typePillRect.size.height);
    [menu popUpMenuPositioningItem:nil atLocation:menuPoint inView:self];
}

- (void)selectPeriodWeekly:(id)sender {
    if ([_delegate respondsToSelector:@selector(widgetView:didSelectPeriod:)]) {
        [_delegate widgetView:self didSelectPeriod:ScrobbleChartPeriodWeekly];
    }
}

- (void)selectPeriodMonthly:(id)sender {
    if ([_delegate respondsToSelector:@selector(widgetView:didSelectPeriod:)]) {
        [_delegate widgetView:self didSelectPeriod:ScrobbleChartPeriodMonthly];
    }
}

- (void)selectPeriodOverall:(id)sender {
    if ([_delegate respondsToSelector:@selector(widgetView:didSelectPeriod:)]) {
        [_delegate widgetView:self didSelectPeriod:ScrobbleChartPeriodOverall];
    }
}

- (void)selectTypeAlbums:(id)sender {
    if ([_delegate respondsToSelector:@selector(widgetView:didSelectType:)]) {
        [_delegate widgetView:self didSelectType:ScrobbleChartTypeAlbums];
    }
}

- (void)selectTypeArtists:(id)sender {
    if ([_delegate respondsToSelector:@selector(widgetView:didSelectType:)]) {
        [_delegate widgetView:self didSelectType:ScrobbleChartTypeArtists];
    }
}

- (void)selectTypeTracks:(id)sender {
    if ([_delegate respondsToSelector:@selector(widgetView:didSelectType:)]) {
        [_delegate widgetView:self didSelectType:ScrobbleChartTypeTracks];
    }
}

- (void)rightMouseDown:(NSEvent *)event {
    if ([_delegate respondsToSelector:@selector(widgetViewRequestsContextMenu:atPoint:)]) {
        NSPoint point = [self convertPoint:event.locationInWindow fromView:nil];
        [_delegate widgetViewRequestsContextMenu:self atPoint:point];
    }
}

#pragma mark - Animation

- (void)animateArrowOpacity:(CGFloat)targetOpacity {
    CGFloat startOpacity = _arrowOpacity;
    NSTimeInterval duration = kArrowFadeDuration;
    NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];

    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1.0/60.0 repeats:YES block:^(NSTimer *t) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                [t invalidate];
                return;
            }

            NSTimeInterval elapsed = [NSDate timeIntervalSinceReferenceDate] - startTime;
            CGFloat progress = MIN(1.0, elapsed / duration);

            // Ease out
            progress = 1.0 - pow(1.0 - progress, 2);

            strongSelf->_arrowOpacity = startOpacity + (targetOpacity - startOpacity) * progress;
            [strongSelf setNeedsDisplay:YES];

            if (progress >= 1.0) {
                [t invalidate];
            }
        }];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    });
}

#pragma mark - Drawing

- (BOOL)isFlipped {
    return YES;  // Use top-left origin for easier layout
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    // Log first draw to help diagnose sizing issues
    static BOOL firstDraw = YES;
    if (firstDraw) {
        NSLog(@"[ScrobbleWidget] FIRST drawRect - bounds: %@, state: %ld, isHovered: %d",
              NSStringFromRect(self.bounds), (long)_state, _isHovered);
        firstDraw = NO;
    }

    // Background (skip if using glass effect - it handles its own background)
    if (!_useGlassBackground) {
        NSColor *bgColor = _backgroundColor ?: [NSColor windowBackgroundColor];
        [bgColor setFill];
        NSRectFill(dirtyRect);
    }

    switch (_state) {
        case ScrobbleWidgetStateLoading:
            [self drawCenteredText:@"Loading..." color:[NSColor secondaryLabelColor]];
            break;

        case ScrobbleWidgetStateNotAuth:
            [self drawCenteredText:@"Not signed in to Last.fm" color:[NSColor secondaryLabelColor]];
            break;

        case ScrobbleWidgetStateEmpty:
            [self drawCenteredText:@"No listening data yet" color:[NSColor secondaryLabelColor]];
            break;

        case ScrobbleWidgetStateError:
            [self drawCenteredText:(_errorMessage ?: @"Error loading data") color:[NSColor systemRedColor]];
            break;

        case ScrobbleWidgetStateReady:
            [self drawReadyState];
            break;
    }

    // Draw hover tooltip for album
    if (_hoveredAlbumIndex >= 0 && _hoveredAlbumIndex < (NSInteger)_topAlbums.count) {
        [self drawAlbumTooltipForIndex:_hoveredAlbumIndex];
    }

    // Draw loading overlay when refreshing (keeps content visible)
    if (_isRefreshing) {
        [self drawRefreshingOverlay];
    }
}

- (void)drawRefreshingOverlay {
    // Semi-transparent overlay
    [[NSColor colorWithWhite:0.0 alpha:0.3] setFill];
    NSRectFillUsingOperation(self.bounds, NSCompositingOperationSourceOver);

    // Loading indicator in center
    CGFloat indicatorSize = 32.0;
    CGFloat centerX = NSMidX(self.bounds);
    CGFloat centerY = NSMidY(self.bounds);

    // Draw spinning dots indicator (simple version - static dots in a circle)
    NSInteger dotCount = 8;
    CGFloat dotRadius = 3.0;
    CGFloat circleRadius = indicatorSize / 2 - dotRadius;

    for (NSInteger i = 0; i < dotCount; i++) {
        CGFloat angle = (CGFloat)i / dotCount * 2 * M_PI - M_PI_2;
        CGFloat dotX = centerX + cos(angle) * circleRadius;
        CGFloat dotY = centerY + sin(angle) * circleRadius;

        // Fade dots based on position
        CGFloat alpha = 0.3 + 0.7 * (CGFloat)i / dotCount;
        [[NSColor colorWithWhite:1.0 alpha:alpha] setFill];

        NSRect dotRect = NSMakeRect(dotX - dotRadius, dotY - dotRadius, dotRadius * 2, dotRadius * 2);
        NSBezierPath *dot = [NSBezierPath bezierPathWithOvalInRect:dotRect];
        [dot fill];
    }
}

- (void)drawReadyState {
    CGFloat contentWidth = self.bounds.size.width - (kPadding * 2);
    CGFloat viewHeight = self.bounds.size.height;
    CGFloat y = kPadding;

    // Profile section (compact header) - shared across all display styles
    CGFloat headerEndY = [self drawProfileSectionAtY:y width:contentWidth];

    // Footer is sticky at bottom
    CGFloat footerY = viewHeight - kFooterHeight - kPadding;

    // Available space for content (between header and footer)
    CGFloat contentStartY = headerEndY;
    CGFloat contentEndY = footerY - kPadding;
    CGFloat availableHeight = contentEndY - contentStartY;

    if (_displayStyle == ScrobbleDisplayStylePlayback2025) {
        // Bubble layout - centered vertically in available space
        CGFloat bubbleSize = MIN(contentWidth, availableHeight);
        CGFloat bubbleStartY = contentStartY + (availableHeight - bubbleSize) / 2;
        [self drawBubbleLayoutAtY:bubbleStartY width:contentWidth availableHeight:bubbleSize];
    } else {
        // Calculate album size based on available width
        CGFloat oldAlbumSize = _calculatedAlbumSize;
        _calculatedAlbumSize = [self calculateAlbumSizeForWidth:contentWidth];

        if (fabs(oldAlbumSize - _calculatedAlbumSize) > 0.1) {
            NSLog(@"[ScrobbleWidget] drawReadyState - bounds: %@, contentWidth: %.1f, albumSize: %.1f -> %.1f, maxAlbums: %ld",
                  NSStringFromRect(self.bounds), contentWidth, oldAlbumSize, _calculatedAlbumSize, (long)_maxAlbums);
        }

        // Album grid (top-aligned)
        [self drawAlbumGridAtY:contentStartY width:contentWidth];
    }

    // Status footer (sticky at bottom)
    [self drawStatusFooterAtY:footerY width:contentWidth];
}

- (CGFloat)drawProfileSectionAtY:(CGFloat)y width:(CGFloat)width {
    CGFloat profileSize = 28.0;
    CGFloat spacing = 6.0;
    CGFloat rowHeight = 28.0;

    // Single header row: [Profile] [< Period >] [< Type >] [Link]
    CGFloat x = kPadding;

    // Profile image (if available)
    NSRect imageRect = NSMakeRect(x, y, profileSize, profileSize);
    if (_profileImage) {
        NSBezierPath *clipPath = [NSBezierPath bezierPathWithRoundedRect:imageRect
                                                                 xRadius:profileSize / 2
                                                                 yRadius:profileSize / 2];
        [NSGraphicsContext saveGraphicsState];
        [clipPath addClip];
        [_profileImage drawInRect:imageRect
                         fromRect:NSZeroRect
                        operation:NSCompositingOperationSourceOver
                         fraction:1.0];
        [NSGraphicsContext restoreGraphicsState];
    } else {
        // Placeholder circle
        [[NSColor tertiaryLabelColor] setFill];
        NSBezierPath *circle = [NSBezierPath bezierPathWithOvalInRect:imageRect];
        [circle fill];
    }
    x += profileSize + spacing;

    // Reload and Link buttons on the far right
    CGFloat buttonSize = 22.0;
    CGFloat buttonGap = 2.0;

    // Link button (rightmost)
    _profileLinkRect = NSMakeRect(kPadding + width - buttonSize, y + (rowHeight - buttonSize) / 2,
                                   buttonSize, buttonSize);
    NSColor *linkColor = _isOverProfileLink ? [NSColor controlAccentColor] : [NSColor secondaryLabelColor];
    [self drawExternalLinkIconInRect:_profileLinkRect color:linkColor];

    // Reload button (left of link button)
    _reloadButtonRect = NSMakeRect(_profileLinkRect.origin.x - buttonSize - buttonGap, y + (rowHeight - buttonSize) / 2,
                                    buttonSize, buttonSize);
    NSColor *reloadColor = _isOverReloadButton ? [NSColor controlAccentColor] : [NSColor secondaryLabelColor];
    [self drawReloadIconInRect:_reloadButtonRect color:reloadColor];

    // Calculate navigation area (between profile and buttons)
    CGFloat navAreaStart = x;
    CGFloat navAreaWidth = width - profileSize - spacing - (buttonSize * 2 + buttonGap) - spacing;
    CGFloat navAreaCenterX = navAreaStart + navAreaWidth / 2;

    // Measure text sizes for dropdown pills
    NSDictionary *titleAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:11 weight:NSFontWeightMedium],
        NSForegroundColorAttributeName: [NSColor labelColor]
    };
    NSString *periodText = _periodTitle ?: @"Weekly";
    NSString *typeText = _typeTitle ?: @"Albums";
    NSSize periodSize = [periodText sizeWithAttributes:titleAttrs];
    NSSize typeSize = [typeText sizeWithAttributes:titleAttrs];

    CGFloat chevronWidth = 8.0, pillPadH = 8.0;
    CGFloat pillGap = 4.0;
    CGFloat pillHeight = 20.0;
    CGFloat centerY = y + rowHeight / 2;

    // Period pill: [Weekly v]
    CGFloat periodPillWidth = pillPadH + periodSize.width + 4 + chevronWidth + pillPadH;
    CGFloat typePillWidth = pillPadH + typeSize.width + 4 + chevronWidth + pillPadH;
    CGFloat totalWidth = periodPillWidth + pillGap + typePillWidth;
    CGFloat startX = navAreaCenterX - totalWidth / 2;

    // Draw period pill
    NSRect periodPill = NSMakeRect(startX, centerY - pillHeight / 2, periodPillWidth, pillHeight);
    _periodPillRect = periodPill;
    NSColor *periodBg = _isOverPeriodPill ? [NSColor colorWithWhite:0.5 alpha:0.2] : [NSColor colorWithWhite:0.5 alpha:0.12];
    [periodBg setFill];
    [[NSBezierPath bezierPathWithRoundedRect:periodPill xRadius:pillHeight/2 yRadius:pillHeight/2] fill];

    // Period text + chevron
    CGFloat periodTextX = startX + pillPadH;
    CGFloat textY = centerY - periodSize.height / 2;
    [periodText drawAtPoint:NSMakePoint(periodTextX, textY) withAttributes:titleAttrs];
    [self drawDropdownChevronAtX:periodTextX + periodSize.width + 4 centerY:centerY
                        hovered:_isOverPeriodPill];

    // Draw type pill
    CGFloat typeStartX = startX + periodPillWidth + pillGap;
    NSRect typePill = NSMakeRect(typeStartX, centerY - pillHeight / 2, typePillWidth, pillHeight);
    _typePillRect = typePill;
    NSColor *typeBg = _isOverTypePill ? [NSColor colorWithWhite:0.5 alpha:0.2] : [NSColor colorWithWhite:0.5 alpha:0.12];
    [typeBg setFill];
    [[NSBezierPath bezierPathWithRoundedRect:typePill xRadius:pillHeight/2 yRadius:pillHeight/2] fill];

    // Type text + chevron
    CGFloat typeTextX = typeStartX + pillPadH;
    [typeText drawAtPoint:NSMakePoint(typeTextX, textY) withAttributes:titleAttrs];
    [self drawDropdownChevronAtX:typeTextX + typeSize.width + 4 centerY:centerY
                        hovered:_isOverTypePill];

    return y + rowHeight + spacing;
}

- (void)drawDropdownChevronAtX:(CGFloat)x centerY:(CGFloat)centerY hovered:(BOOL)hovered {
    CGFloat size = 4.0;
    NSColor *color = hovered ? [NSColor controlAccentColor] : [NSColor secondaryLabelColor];

    NSBezierPath *chevron = [NSBezierPath bezierPath];
    chevron.lineWidth = 1.2;
    chevron.lineCapStyle = NSLineCapStyleRound;
    chevron.lineJoinStyle = NSLineJoinStyleRound;

    // Down chevron (v shape)
    [chevron moveToPoint:NSMakePoint(x, centerY - size/2)];
    [chevron lineToPoint:NSMakePoint(x + size, centerY + size/2)];
    [chevron lineToPoint:NSMakePoint(x + size*2, centerY - size/2)];

    [color setStroke];
    [chevron stroke];
}

- (void)drawReloadIconInRect:(NSRect)rect color:(NSColor *)color {
    // Draw a circular arrow (refresh icon)
    CGFloat inset = 5.0;
    NSRect iconRect = NSInsetRect(rect, inset, inset);
    CGFloat cx = NSMidX(iconRect);
    CGFloat cy = NSMidY(iconRect);
    CGFloat radius = iconRect.size.width / 2 - 1;

    NSBezierPath *path = [NSBezierPath bezierPath];
    path.lineWidth = 1.5;
    path.lineCapStyle = NSLineCapStyleRound;

    // Draw arc (about 270 degrees, leaving a gap for the arrow)
    CGFloat startAngle = 45.0;   // degrees
    CGFloat endAngle = 315.0;    // degrees
    [path appendBezierPathWithArcWithCenter:NSMakePoint(cx, cy)
                                     radius:radius
                                 startAngle:startAngle
                                   endAngle:endAngle
                                  clockwise:NO];

    [color setStroke];
    [path stroke];

    // Draw arrowhead at the end of the arc
    CGFloat arrowAngle = endAngle * M_PI / 180.0;
    CGFloat arrowX = cx + radius * cos(arrowAngle);
    CGFloat arrowY = cy + radius * sin(arrowAngle);

    CGFloat arrowSize = 3.0;
    NSBezierPath *arrow = [NSBezierPath bezierPath];
    arrow.lineWidth = 1.5;
    arrow.lineCapStyle = NSLineCapStyleRound;
    arrow.lineJoinStyle = NSLineJoinStyleRound;

    // Arrow pointing in direction of arc travel (clockwise at this point)
    [arrow moveToPoint:NSMakePoint(arrowX - arrowSize, arrowY + arrowSize)];
    [arrow lineToPoint:NSMakePoint(arrowX, arrowY)];
    [arrow lineToPoint:NSMakePoint(arrowX + arrowSize, arrowY + arrowSize)];

    [arrow stroke];
}

- (void)drawExternalLinkIconInRect:(NSRect)rect color:(NSColor *)color {
    // Draw a simple external link icon (arrow pointing out of box)
    CGFloat inset = 5.0;
    NSRect iconRect = NSInsetRect(rect, inset, inset);
    CGFloat size = iconRect.size.width;

    NSBezierPath *path = [NSBezierPath bezierPath];
    path.lineWidth = 1.5;
    path.lineCapStyle = NSLineCapStyleRound;
    path.lineJoinStyle = NSLineJoinStyleRound;

    CGFloat x = iconRect.origin.x;
    CGFloat y = iconRect.origin.y;

    // Draw box (bottom-left corner open)
    [path moveToPoint:NSMakePoint(x + size * 0.4, y)];
    [path lineToPoint:NSMakePoint(x, y)];
    [path lineToPoint:NSMakePoint(x, y + size)];
    [path lineToPoint:NSMakePoint(x + size, y + size)];
    [path lineToPoint:NSMakePoint(x + size, y + size * 0.6)];

    // Draw arrow
    [path moveToPoint:NSMakePoint(x + size * 0.4, y + size * 0.6)];
    [path lineToPoint:NSMakePoint(x + size, y)];

    // Arrow head
    [path moveToPoint:NSMakePoint(x + size * 0.6, y)];
    [path lineToPoint:NSMakePoint(x + size, y)];
    [path lineToPoint:NSMakePoint(x + size, y + size * 0.4)];

    [color setStroke];
    [path stroke];
}

- (CGFloat)drawBubbleLayoutAtY:(CGFloat)y width:(CGFloat)width availableHeight:(CGFloat)availableHeight {
    // Clear stored rects
    [_albumRects removeAllObjects];

    if (_topAlbums.count == 0) {
        return y;
    }

    // Normalized circle positions (centerX, centerY, radius) in 0..1 space
    struct CircleLayout { float centerX; float centerY; float radius; };
    static const CircleLayout circles[10] = {
        {0.7576f, 0.2424f, 0.2147f},  // circle 1
        {0.5791f, 0.7355f, 0.1801f},  // circle 2
        {0.2750f, 0.6504f, 0.1316f},  // circle 3
        {0.1524f, 0.4207f, 0.1247f},  // circle 4
        {0.2803f, 0.2312f, 0.0997f},  // circle 5
        {0.4602f, 0.1589f, 0.0900f},  // circle 6
        {0.4695f, 0.3374f, 0.0845f},  // circle 7
        {0.5686f, 0.4725f, 0.0790f},  // circle 8
        {0.4117f, 0.4902f, 0.0748f},  // circle 9
        {0.3324f, 0.3817f, 0.0554f},  // circle 10
    };

    // Use a square area for the bubble layout (passed in, already computed for centering)
    CGFloat areaSize = MIN(width, availableHeight);
    if (areaSize < 100) areaSize = width;  // Fallback

    CGFloat offsetX = kPadding + (width - areaSize) / 2;
    CGFloat offsetY = y;

    NSInteger count = MIN((NSInteger)_topAlbums.count, 10);

    for (NSInteger i = 0; i < count; i++) {
        TopAlbum *album = _topAlbums[i];
        const CircleLayout &layout = circles[i];

        CGFloat cx = offsetX + layout.centerX * areaSize;
        CGFloat cy = offsetY + layout.centerY * areaSize;
        CGFloat r = layout.radius * areaSize;
        CGFloat diameter = r * 2;

        NSRect circleRect = NSMakeRect(cx - r, cy - r, diameter, diameter);

        // Store rect for hit testing
        [_albumRects addObject:[NSValue valueWithRect:circleRect]];

        // Skip actual drawing during animation (layers handle visuals)
        if (_isAnimatingTransition) continue;

        // Clip to circle
        NSBezierPath *clipPath = [NSBezierPath bezierPathWithOvalInRect:circleRect];

        // Try to get loaded image
        NSImage *albumImage = nil;
        if (album.imageURL && _albumImages) {
            albumImage = _albumImages[album.imageURL];
        }

        if (albumImage) {
            [NSGraphicsContext saveGraphicsState];
            [clipPath addClip];
            [self drawImage:albumImage inRect:circleRect];
            [NSGraphicsContext restoreGraphicsState];
        } else {
            // Placeholder circle
            [[NSColor tertiaryLabelColor] setFill];
            [clipPath fill];

            // Draw name centered in placeholder
            if (album.name.length > 0) {
                NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
                paraStyle.alignment = NSTextAlignmentCenter;
                paraStyle.lineBreakMode = NSLineBreakByWordWrapping;

                CGFloat fontSize = MAX(8.0, r * 0.25);
                NSDictionary *nameAttrs = @{
                    NSFontAttributeName: [NSFont systemFontOfSize:fontSize],
                    NSForegroundColorAttributeName: [NSColor secondaryLabelColor],
                    NSParagraphStyleAttributeName: paraStyle
                };

                CGFloat textInset = r * 0.3;
                NSRect textRect = NSMakeRect(cx - r + textInset, cy - r * 0.4,
                                             diameter - textInset * 2, r * 0.8);
                [album.name drawInRect:textRect withAttributes:nameAttrs];
            }
        }

        // Draw subtle circle border
        [[NSColor colorWithWhite:0.5 alpha:0.2] setStroke];
        [clipPath setLineWidth:1.0];
        [clipPath stroke];

        // Rank badge removed from bubbles - shown in tooltip instead
    }

    return offsetY + areaSize + kAlbumSpacing;
}

- (CGFloat)drawAlbumGridAtY:(CGFloat)y width:(CGFloat)width {
    // Clear stored rects
    [_albumRects removeAllObjects];

    if (_topAlbums.count == 0) {
        return y;
    }

    CGFloat albumSize = _calculatedAlbumSize;
    CGFloat spacing = kAlbumSpacing;

    // Calculate how many albums fit per row
    NSInteger albumsPerRow = (NSInteger)((width + spacing) / (albumSize + spacing));
    if (albumsPerRow < 1) albumsPerRow = 1;

    // Center the grid
    CGFloat totalGridWidth = albumsPerRow * albumSize + (albumsPerRow - 1) * spacing;
    CGFloat startX = kPadding + (width - totalGridWidth) / 2;

    CGFloat x = startX;
    NSInteger col = 0;

    for (TopAlbum *album in _topAlbums) {
        NSRect albumRect = NSMakeRect(x, y, albumSize, albumSize);

        // Store rect for hit testing
        [_albumRects addObject:[NSValue valueWithRect:albumRect]];

        // Skip actual drawing during animation (layers handle visuals)
        if (!_isAnimatingTransition) {
            // Try to get loaded image
            NSImage *albumImage = nil;
            if (album.imageURL && _albumImages) {
                albumImage = _albumImages[album.imageURL];
            }

            if (albumImage) {
                // Draw the album artwork scaled to fill
                [self drawImage:albumImage inRect:albumRect];
            } else {
                // Draw placeholder
                [[NSColor tertiaryLabelColor] setFill];
                NSRectFill(albumRect);

                // Draw album name centered in placeholder (below rank badge area)
                if (album.name.length > 0) {
                    NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
                    paraStyle.alignment = NSTextAlignmentCenter;
                    paraStyle.lineBreakMode = NSLineBreakByWordWrapping;

                    NSDictionary *nameAttrs = @{
                        NSFontAttributeName: [NSFont systemFontOfSize:10],
                        NSForegroundColorAttributeName: [NSColor secondaryLabelColor],
                        NSParagraphStyleAttributeName: paraStyle
                    };

                    // Inset to avoid rank badge (top-left) and leave margins
                    NSRect textRect = NSMakeRect(x + 4, y + 24, albumSize - 8, albumSize - 28);
                    [album.name drawInRect:textRect withAttributes:nameAttrs];
                }
            }

            // Draw rank badge (semi-transparent background)
            NSString *rank = [NSString stringWithFormat:@"%ld", (long)album.rank];
            NSDictionary *rankAttrs = @{
                NSFontAttributeName: [NSFont systemFontOfSize:9 weight:NSFontWeightBold],
                NSForegroundColorAttributeName: [NSColor whiteColor]
            };
            NSSize rankSize = [rank sizeWithAttributes:rankAttrs];
            NSRect badgeRect = NSMakeRect(x + 2, y + 2, rankSize.width + 6, rankSize.height + 2);

            [[NSColor colorWithWhite:0 alpha:0.6] setFill];
            NSBezierPath *badgePath = [NSBezierPath bezierPathWithRoundedRect:badgeRect xRadius:3 yRadius:3];
            [badgePath fill];

            [rank drawAtPoint:NSMakePoint(x + 5, y + 3) withAttributes:rankAttrs];
        }

        col++;
        if (col >= albumsPerRow) {
            col = 0;
            x = startX;
            y += albumSize + spacing;
        } else {
            x += albumSize + spacing;
        }
    }

    // If we ended mid-row, move to next line
    if (col > 0) {
        y += albumSize + spacing;
    }

    return y;
}

- (void)drawImage:(NSImage *)image inRect:(NSRect)rect {
    NSSize imageSize = image.size;
    if (imageSize.width <= 0 || imageSize.height <= 0) return;

    // Scale to fill (crop if needed)
    CGFloat imageAspect = imageSize.width / imageSize.height;
    CGFloat viewAspect = rect.size.width / rect.size.height;

    NSRect sourceRect;
    if (imageAspect > viewAspect) {
        // Image is wider - crop sides
        CGFloat newWidth = imageSize.height * viewAspect;
        CGFloat x = (imageSize.width - newWidth) / 2;
        sourceRect = NSMakeRect(x, 0, newWidth, imageSize.height);
    } else {
        // Image is taller - crop top/bottom
        CGFloat newHeight = imageSize.width / viewAspect;
        CGFloat y = (imageSize.height - newHeight) / 2;
        sourceRect = NSMakeRect(0, y, imageSize.width, newHeight);
    }

    [image drawInRect:rect
             fromRect:sourceRect
            operation:NSCompositingOperationSourceOver
             fraction:1.0
       respectFlipped:YES
                hints:@{NSImageHintInterpolation: @(NSImageInterpolationHigh)}];
}

- (void)drawStatusFooterAtY:(CGFloat)y width:(CGFloat)width {
    NSDictionary *statusAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:10],
        NSForegroundColorAttributeName: [NSColor tertiaryLabelColor]
    };
    NSDictionary *errorAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:10],
        NSForegroundColorAttributeName: [NSColor systemOrangeColor]
    };

    // If there's an error message in Ready state, show it instead of normal status
    if (_errorMessage.length > 0 && _state == ScrobbleWidgetStateReady) {
        // Truncate long error messages
        NSString *displayError = _errorMessage;
        if (displayError.length > 60) {
            displayError = [[displayError substringToIndex:57] stringByAppendingString:@"..."];
        }

        // Draw error with retry hint
        NSString *errorText = [NSString stringWithFormat:@"%@ (click refresh)", displayError];
        NSRect errorRect = NSMakeRect(kPadding, y, width, 14);
        [errorText drawInRect:errorRect withAttributes:errorAttrs];
        return;
    }

    // Build footer text per spec:
    // "15 day streak | 7 scrobbles today | 2 queued         Updated 14:32"
    // "15 day streak (continue today) | 0 scrobbles today   Updated 14:32"
    // "42+ day streak... | 5 scrobbles today                Updated 14:32"
    // "7 scrobbles today                                    Updated 14:32"

    NSMutableString *statusText = [NSMutableString string];

    // Streak (shown first when >= 2 days)
    if (_streakEnabled && _streakDays >= 2) {
        if (_streakDiscoveryInProgress) {
            [statusText appendFormat:@"%ld+ day streak...", (long)_streakDays];
        } else if (_streakNeedsContinuation) {
            [statusText appendFormat:@"%ld day streak (continue today)", (long)_streakDays];
        } else {
            [statusText appendFormat:@"%ld day streak", (long)_streakDays];
        }
        [statusText appendString:@" | "];
    }

    // Scrobbled today
    if (_scrobbledToday >= 200) {
        [statusText appendString:@"200+ scrobbles today"];
    } else {
        [statusText appendFormat:@"%ld scrobbles today", (long)_scrobbledToday];
    }

    // Queue status
    if (_queueCount > 0) {
        [statusText appendFormat:@" | %ld queued", (long)_queueCount];
    }

    NSRect statusRect = NSMakeRect(kPadding, y, width, 14);
    [statusText drawInRect:statusRect withAttributes:statusAttrs];

    // Last updated timestamp (right-aligned)
    if (_lastUpdated) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.timeStyle = NSDateFormatterShortStyle;
        formatter.dateStyle = NSDateFormatterNoStyle;

        NSString *timeText = [NSString stringWithFormat:@"Updated %@", [formatter stringFromDate:_lastUpdated]];
        NSSize timeSize = [timeText sizeWithAttributes:statusAttrs];
        NSRect timeRect = NSMakeRect(kPadding + width - timeSize.width, y, timeSize.width, 14);
        [timeText drawInRect:timeRect withAttributes:statusAttrs];
    }
}

#pragma mark - Album Tooltip

- (void)drawAlbumTooltipForIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)_topAlbums.count || index >= (NSInteger)_albumRects.count) {
        return;
    }

    TopAlbum *album = _topAlbums[index];
    NSRect albumRect = [_albumRects[index] rectValue];

    // Build tooltip text
    NSString *artistText = album.artist.length > 0 ? album.artist : @"Unknown Artist";
    NSString *albumText = album.name.length > 0 ? album.name : @"Unknown Album";
    // Include rank in tooltip for bubble view
    NSString *playsText;
    if (_displayStyle == ScrobbleDisplayStylePlayback2025 && album.rank > 0) {
        playsText = [NSString stringWithFormat:@"#%ld - %ld plays", (long)album.rank, (long)album.playcount];
    } else {
        playsText = [NSString stringWithFormat:@"%ld plays", (long)album.playcount];
    }

    // Calculate tooltip size
    NSDictionary *titleAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:11 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName: [NSColor whiteColor]
    };
    NSDictionary *subtitleAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:10],
        NSForegroundColorAttributeName: [NSColor colorWithWhite:0.85 alpha:1.0]
    };
    NSDictionary *playsAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:9],
        NSForegroundColorAttributeName: [NSColor colorWithWhite:0.7 alpha:1.0]
    };

    NSSize albumSize = [albumText sizeWithAttributes:titleAttrs];
    NSSize artistSize = [artistText sizeWithAttributes:subtitleAttrs];
    NSSize playsSize = [playsText sizeWithAttributes:playsAttrs];

    CGFloat tooltipWidth = MAX(albumSize.width, MAX(artistSize.width, playsSize.width)) + 16;
    CGFloat tooltipHeight = albumSize.height + artistSize.height + playsSize.height + 14;

    // Clamp width
    tooltipWidth = MIN(tooltipWidth, 250);
    tooltipWidth = MAX(tooltipWidth, 100);

    // Position tooltip below the album, centered
    CGFloat tooltipX = albumRect.origin.x + (albumRect.size.width - tooltipWidth) / 2;
    CGFloat tooltipY = albumRect.origin.y + albumRect.size.height + 4;

    // Keep tooltip within view bounds
    if (tooltipX < kPadding) tooltipX = kPadding;
    if (tooltipX + tooltipWidth > self.bounds.size.width - kPadding) {
        tooltipX = self.bounds.size.width - kPadding - tooltipWidth;
    }

    // If tooltip would go below view, show it above the album instead
    if (tooltipY + tooltipHeight > self.bounds.size.height - kPadding) {
        tooltipY = albumRect.origin.y - tooltipHeight - 4;
    }

    NSRect tooltipRect = NSMakeRect(tooltipX, tooltipY, tooltipWidth, tooltipHeight);

    // Draw tooltip background with shadow
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [[NSColor blackColor] colorWithAlphaComponent:0.4];
    shadow.shadowOffset = NSMakeSize(0, -2);
    shadow.shadowBlurRadius = 6;

    [NSGraphicsContext saveGraphicsState];
    [shadow set];

    [[NSColor colorWithWhite:0.15 alpha:0.95] setFill];
    NSBezierPath *bgPath = [NSBezierPath bezierPathWithRoundedRect:tooltipRect xRadius:6 yRadius:6];
    [bgPath fill];

    [NSGraphicsContext restoreGraphicsState];

    // Draw border
    [[NSColor colorWithWhite:0.3 alpha:1.0] setStroke];
    [bgPath stroke];

    // Draw text
    CGFloat textX = tooltipRect.origin.x + 8;
    CGFloat textY = tooltipRect.origin.y + 6;

    NSRect albumTextRect = NSMakeRect(textX, textY, tooltipWidth - 16, albumSize.height);
    [albumText drawInRect:albumTextRect withAttributes:titleAttrs];

    textY += albumSize.height + 2;
    NSRect artistTextRect = NSMakeRect(textX, textY, tooltipWidth - 16, artistSize.height);
    [artistText drawInRect:artistTextRect withAttributes:subtitleAttrs];

    textY += artistSize.height + 2;
    NSRect playsTextRect = NSMakeRect(textX, textY, tooltipWidth - 16, playsSize.height);
    [playsText drawInRect:playsTextRect withAttributes:playsAttrs];
}

#pragma mark - Helper Methods

- (void)drawCenteredText:(NSString *)text color:(NSColor *)color {
    NSDictionary *attrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:13],
        NSForegroundColorAttributeName: color
    };

    NSSize size = [text sizeWithAttributes:attrs];
    CGFloat x = (self.bounds.size.width - size.width) / 2;
    CGFloat y = (self.bounds.size.height - size.height) / 2;

    [text drawAtPoint:NSMakePoint(x, y) withAttributes:attrs];
}

#pragma mark - Public Methods

- (void)setDisplayStyle:(ScrobbleDisplayStyle)style animated:(BOOL)animated {
    if (_displayStyle == style) return;

    if (!animated || !self.window || _topAlbums.count == 0) {
        _displayStyle = style;
        [self setNeedsDisplay:YES];
        return;
    }

    // Capture current item rects and corner radii
    NSArray<NSValue *> *oldRects = [_albumRects copy];
    BOOL wasGrid = (_displayStyle == ScrobbleDisplayStyleDefault);
    CGFloat oldCornerRadius = wasGrid ? 4.0 : 1000.0;  // grid uses rounded rect, bubble uses circle

    // Switch to new style and redraw to get new rects (but suppress actual drawing)
    _displayStyle = style;
    _isAnimatingTransition = YES;
    [self display];  // Force synchronous draw to populate new _albumRects (items not drawn)

    NSArray<NSValue *> *newRects = [_albumRects copy];
    BOOL isGrid = (_displayStyle == ScrobbleDisplayStyleDefault);
    CGFloat newCornerRadius = isGrid ? 4.0 : 1000.0;

    NSInteger count = MIN((NSInteger)oldRects.count, (NSInteger)newRects.count);
    if (count == 0) return;

    NSTimeInterval duration = 0.4;
    CAMediaTimingFunction *timing = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

    // Create animated layers for each item
    NSMutableArray<CALayer *> *animLayers = [NSMutableArray array];

    for (NSInteger i = 0; i < count; i++) {
        NSRect fromRect = [oldRects[i] rectValue];
        NSRect toRect = [newRects[i] rectValue];

        // Get image for this item
        NSImage *itemImage = nil;
        if (i < (NSInteger)_topAlbums.count) {
            TopAlbum *album = _topAlbums[i];
            if (album.imageURL && _albumImages) {
                itemImage = _albumImages[album.imageURL];
            }
        }

        CALayer *itemLayer = [CALayer layer];
        itemLayer.frame = fromRect;
        if (itemImage) {
            itemLayer.contents = itemImage;
            itemLayer.contentsGravity = kCAGravityResizeAspectFill;
        } else {
            itemLayer.backgroundColor = [NSColor tertiaryLabelColor].CGColor;
        }
        itemLayer.masksToBounds = YES;
        CGFloat fromRadius = MIN(oldCornerRadius, MIN(fromRect.size.width, fromRect.size.height) / 2);
        itemLayer.cornerRadius = fromRadius;

        [self.layer addSublayer:itemLayer];
        [animLayers addObject:itemLayer];

        // Animate bounds (size change)
        CABasicAnimation *boundsAnim = [CABasicAnimation animationWithKeyPath:@"bounds"];
        boundsAnim.fromValue = [NSValue valueWithRect:NSMakeRect(0, 0, fromRect.size.width, fromRect.size.height)];
        boundsAnim.toValue = [NSValue valueWithRect:NSMakeRect(0, 0, toRect.size.width, toRect.size.height)];
        boundsAnim.duration = duration;
        boundsAnim.timingFunction = timing;

        // Animate position (center point translation)
        CABasicAnimation *posAnim = [CABasicAnimation animationWithKeyPath:@"position"];
        CGPoint fromCenter = CGPointMake(NSMidX(fromRect), NSMidY(fromRect));
        CGPoint toCenter = CGPointMake(NSMidX(toRect), NSMidY(toRect));
        posAnim.fromValue = [NSValue valueWithPoint:NSPointFromCGPoint(fromCenter)];
        posAnim.toValue = [NSValue valueWithPoint:NSPointFromCGPoint(toCenter)];
        posAnim.duration = duration;
        posAnim.timingFunction = timing;

        // Animate corner radius (square-ish to circle or vice versa)
        CGFloat toRadius = MIN(newCornerRadius, MIN(toRect.size.width, toRect.size.height) / 2);
        CABasicAnimation *radiusAnim = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
        radiusAnim.fromValue = @(fromRadius);
        radiusAnim.toValue = @(toRadius);
        radiusAnim.duration = duration;
        radiusAnim.timingFunction = timing;

        // Group animations
        CAAnimationGroup *group = [CAAnimationGroup animation];
        group.animations = @[boundsAnim, posAnim, radiusAnim];
        group.duration = duration;
        group.fillMode = kCAFillModeForwards;
        group.removedOnCompletion = NO;

        [itemLayer addAnimation:group forKey:@"transition"];

        // Set final values
        itemLayer.frame = toRect;
        itemLayer.cornerRadius = toRadius;
    }

    // Remove overlay layers after animation completes
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        for (CALayer *layer in animLayers) {
            [layer removeFromSuperlayer];
        }
        self->_isAnimatingTransition = NO;
        [self setNeedsDisplay:YES];
    });
}

- (void)refreshDisplay {
    [self setNeedsDisplay:YES];
}

@end
