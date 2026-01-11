//
//  SimPlaylistHeaderBar.mm
//  foo_simplaylist_mac
//

#import "SimPlaylistHeaderBar.h"
#import "../Core/ColumnDefinition.h"
#import "../Core/ConfigHelper.h"

static const CGFloat kResizeHandleWidth = 6.0;

static CGFloat getHeaderHeight() {
    int64_t sizeSetting = simplaylist_config::getConfigInt(
        simplaylist_config::kColumnHeaderSize,
        simplaylist_config::kDefaultColumnHeaderSize);
    switch (sizeSetting) {
        case 0: return 22.0;  // Compact
        case 2: return 34.0;  // Large
        default: return 28.0; // Normal
    }
}

static CGFloat getHeaderFontSize() {
    int64_t sizeSetting = simplaylist_config::getConfigInt(
        simplaylist_config::kColumnHeaderSize,
        simplaylist_config::kDefaultColumnHeaderSize);
    switch (sizeSetting) {
        case 0: return 11.0;  // Compact
        case 2: return 13.0;  // Large (+2)
        default: return 12.0; // Normal (+1)
    }
}

@interface SimPlaylistHeaderBar ()
@property (nonatomic, assign) CGFloat scrollOffset;
@property (nonatomic, assign) NSInteger resizingColumn;      // -1 if not resizing
@property (nonatomic, assign) CGFloat resizeStartX;
@property (nonatomic, assign) CGFloat resizeStartWidth;
@property (nonatomic, assign) NSInteger draggingColumn;      // -1 if not dragging
@property (nonatomic, assign) CGFloat dragStartX;
@property (nonatomic, assign) NSInteger dropTargetIndex;
@property (nonatomic, assign) NSInteger hoveredColumn;
@property (nonatomic, strong) NSTrackingArea *trackingArea;
@end

@implementation SimPlaylistHeaderBar

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _columns = @[];
    _groupColumnWidth = 80;
    _scrollOffset = 0;
    _resizingColumn = -1;
    _draggingColumn = -1;
    _dropTargetIndex = -1;
    _hoveredColumn = -1;
}

- (BOOL)isFlipped {
    return YES;
}

- (void)setScrollOffset:(CGFloat)offset {
    _scrollOffset = offset;
    [self setNeedsDisplay:YES];
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];

    if (_trackingArea) {
        [self removeTrackingArea:_trackingArea];
    }

    _trackingArea = [[NSTrackingArea alloc]
                     initWithRect:self.bounds
                          options:(NSTrackingMouseMoved |
                                   NSTrackingMouseEnteredAndExited |
                                   NSTrackingActiveInKeyWindow |
                                   NSTrackingInVisibleRect)
                            owner:self
                         userInfo:nil];
    [self addTrackingArea:_trackingArea];
}

#pragma mark - Layout

- (CGFloat)xOffsetForColumn:(NSInteger)columnIndex {
    CGFloat x = _groupColumnWidth - _scrollOffset;
    for (NSInteger i = 0; i < columnIndex && i < (NSInteger)_columns.count; i++) {
        x += _columns[i].width;
    }
    return x;
}

- (NSInteger)columnAtX:(CGFloat)x {
    CGFloat currentX = _groupColumnWidth - _scrollOffset;

    for (NSInteger i = 0; i < (NSInteger)_columns.count; i++) {
        CGFloat colWidth = _columns[i].width;
        if (x >= currentX && x < currentX + colWidth) {
            return i;
        }
        currentX += colWidth;
    }
    return -1;
}

// Returns -2 for group column resize handle, -1 for none, >=0 for regular column
- (NSInteger)resizeHandleAtX:(CGFloat)x {
    // Check group column resize handle first (right edge of group column)
    if (_groupColumnWidth > 0) {
        CGFloat groupHandleX = _groupColumnWidth - kResizeHandleWidth / 2;
        if (x >= groupHandleX && x <= groupHandleX + kResizeHandleWidth) {
            return -2;  // Special value for group column
        }
    }

    CGFloat currentX = _groupColumnWidth - _scrollOffset;

    for (NSInteger i = 0; i < (NSInteger)_columns.count; i++) {
        CGFloat colWidth = _columns[i].width;
        CGFloat handleX = currentX + colWidth - kResizeHandleWidth / 2;

        if (x >= handleX && x <= handleX + kResizeHandleWidth) {
            return i;
        }
        currentX += colWidth;
    }
    return -1;
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    CGFloat width = self.bounds.size.width;

    // Background - match native NSTableHeaderView styling
    [[self headerBackgroundColor] setFill];
    NSRectFill(self.bounds);

    // Top highlight line (subtle lighter edge like native headers)
    // Skip for accent modes - looks better with clean edge
    int64_t accentSetting = simplaylist_config::getConfigInt(
        simplaylist_config::kHeaderAccentColor,
        simplaylist_config::kDefaultHeaderAccentColor);
    if (accentSetting == 0) {
        [[self headerTopHighlightColor] setFill];
        NSRectFill(NSMakeRect(0, 0, width, 1));
    }

    // Group column area is empty (no header cell needed)
    // Just draw a subtle separator at the right edge
    if (_groupColumnWidth > 0) {
        [[self headerDividerColor] setFill];
        NSRectFill(NSMakeRect(_groupColumnWidth - 1, 5, 1, getHeaderHeight() - 10));
    }

    // Draw column headers - start right after group column
    CGFloat x = _groupColumnWidth - _scrollOffset;

    for (NSInteger i = 0; i < (NSInteger)_columns.count; i++) {
        ColumnDefinition *col = _columns[i];
        NSRect colRect = NSMakeRect(x, 0, col.width, getHeaderHeight());

        // Only draw if visible
        if (NSMaxX(colRect) > _groupColumnWidth && NSMinX(colRect) < self.bounds.size.width) {
            // Clip to after group column
            if (NSMinX(colRect) < _groupColumnWidth) {
                CGFloat clipAmount = _groupColumnWidth - NSMinX(colRect);
                colRect.origin.x = _groupColumnWidth;
                colRect.size.width -= clipAmount;
            }

            BOOL isHighlighted = (i == _hoveredColumn);
            BOOL isDragging = (i == _draggingColumn);

            if (!isDragging) {
                [self drawHeaderCell:col.name inRect:colRect highlighted:isHighlighted];
            }

            // Draw column divider
            [[self headerDividerColor] setFill];
            NSRectFill(NSMakeRect(x + col.width - 1, 5, 1, getHeaderHeight() - 10));
        }

        x += col.width;
    }

    // Draw drop indicator during drag
    if (_draggingColumn >= 0 && _dropTargetIndex >= 0) {
        CGFloat indicatorX = [self xOffsetForColumn:_dropTargetIndex];
        [[NSColor selectedContentBackgroundColor] setFill];
        NSRectFill(NSMakeRect(indicatorX - 1, 0, 3, getHeaderHeight()));
    }

    // Draw dragged column overlay
    if (_draggingColumn >= 0 && _draggingColumn < (NSInteger)_columns.count) {
        ColumnDefinition *dragCol = _columns[_draggingColumn];
        CGFloat dragX = _dragStartX - _scrollOffset;
        NSRect dragRect = NSMakeRect(dragX, 0, dragCol.width, getHeaderHeight());

        // Semi-transparent background
        [[[self headerBackgroundColor] colorWithAlphaComponent:0.9] setFill];
        NSRectFill(dragRect);

        [self drawHeaderCell:dragCol.name inRect:dragRect highlighted:YES];

        // Border
        [[NSColor selectedContentBackgroundColor] setStroke];
        NSBezierPath *borderPath = [NSBezierPath bezierPathWithRect:NSInsetRect(dragRect, 0.5, 0.5)];
        [borderPath stroke];
    }

    // Bottom border (darker separator line)
    [[self headerBottomBorderColor] setFill];
    NSRectFill(NSMakeRect(0, getHeaderHeight() - 1, width, 1));
}

- (void)drawHeaderCell:(NSString *)title inRect:(NSRect)rect highlighted:(BOOL)highlighted {
    if (highlighted) {
        [[[NSColor labelColor] colorWithAlphaComponent:0.06] setFill];
        NSRectFill(rect);
    }

    // Native header: 4px left padding, text vertically centered
    NSRect textRect = rect;
    textRect.origin.x += 4;
    textRect.size.width -= 8;  // 4px each side

    NSFont *font = [NSFont systemFontOfSize:getHeaderFontSize() weight:NSFontWeightRegular];

    NSColor *textColor = [NSColor labelColor];

    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineBreakMode = NSLineBreakByTruncatingTail;

    NSDictionary *attrs = @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: textColor,
        NSParagraphStyleAttributeName: style
    };

    // Calculate vertical centering
    NSSize textSize = [title sizeWithAttributes:attrs];
    CGFloat yOffset = (rect.size.height - textSize.height) / 2.0;
    textRect.origin.y = yOffset;
    textRect.size.height = textSize.height;

    [title drawInRect:textRect withAttributes:attrs];
}

#pragma mark - Colors (Native NSTableHeaderView-matching)

- (NSColor *)headerBackgroundColor {
    int64_t accentSetting = simplaylist_config::getConfigInt(
        simplaylist_config::kHeaderAccentColor,
        simplaylist_config::kDefaultHeaderAccentColor);

    if (accentSetting == 1) {
        // Tinted: blend control background with accent color (~20%)
        NSColor *base = [NSColor controlBackgroundColor];
        NSColor *accent = [NSColor controlAccentColor];
        // Convert to sRGB for blending
        NSColor *baseRGB = [base colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
        NSColor *accentRGB = [accent colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
        if (baseRGB && accentRGB) {
            CGFloat blendFactor = 0.2;
            CGFloat r = baseRGB.redComponent * (1 - blendFactor) + accentRGB.redComponent * blendFactor;
            CGFloat g = baseRGB.greenComponent * (1 - blendFactor) + accentRGB.greenComponent * blendFactor;
            CGFloat b = baseRGB.blueComponent * (1 - blendFactor) + accentRGB.blueComponent * blendFactor;
            return [NSColor colorWithSRGBRed:r green:g blue:b alpha:1.0];
        }
        return base;
    }
    // None: match native table header
    return [NSColor controlBackgroundColor];
}

- (NSColor *)headerTopHighlightColor {
    // Subtle top highlight - slightly lighter than background
    BOOL isDark = [NSApp.effectiveAppearance bestMatchFromAppearancesWithNames:
                   @[NSAppearanceNameDarkAqua, NSAppearanceNameAqua]] == NSAppearanceNameDarkAqua;
    if (isDark) {
        return [[NSColor whiteColor] colorWithAlphaComponent:0.08];
    } else {
        return [[NSColor whiteColor] colorWithAlphaComponent:0.5];
    }
}

- (NSColor *)headerBottomBorderColor {
    // Bottom border - same as column separators
    return [NSColor separatorColor];
}

- (NSColor *)headerDividerColor {
    // Column dividers - subtle separator color
    return [NSColor separatorColor];
}

#pragma mark - Mouse Events

- (void)mouseDown:(NSEvent *)event {
    NSPoint location = [self convertPoint:event.locationInWindow fromView:nil];

    // Check for resize handle first
    NSInteger resizeHandle = [self resizeHandleAtX:location.x];
    if (resizeHandle == -2) {
        // Group column resize
        _resizingColumn = -2;
        _resizeStartX = location.x;
        _resizeStartWidth = _groupColumnWidth;
        [[NSCursor resizeLeftRightCursor] push];
        return;
    } else if (resizeHandle >= 0) {
        _resizingColumn = resizeHandle;
        _resizeStartX = location.x;
        _resizeStartWidth = _columns[resizeHandle].width;
        [[NSCursor resizeLeftRightCursor] push];
        return;
    }

    // Check for column header click
    NSInteger column = [self columnAtX:location.x];
    if (column >= 0) {
        _draggingColumn = column;
        _dragStartX = [self xOffsetForColumn:column] + _scrollOffset;
        _dropTargetIndex = -1;
    }
}

- (void)mouseDragged:(NSEvent *)event {
    NSPoint location = [self convertPoint:event.locationInWindow fromView:nil];

    if (_resizingColumn == -2) {
        // Resizing group column
        CGFloat delta = location.x - _resizeStartX;
        CGFloat newWidth = MAX(40, MIN(300, _resizeStartWidth + delta));  // Clamp 40-300

        _groupColumnWidth = newWidth;

        if ([_delegate respondsToSelector:@selector(headerBar:didResizeGroupColumnToWidth:)]) {
            [_delegate headerBar:self didResizeGroupColumnToWidth:newWidth];
        }

        [self setNeedsDisplay:YES];

    } else if (_resizingColumn >= 0) {
        // Resizing regular column
        CGFloat delta = location.x - _resizeStartX;
        CGFloat newWidth = MAX(40, _resizeStartWidth + delta);  // Min width 40

        ColumnDefinition *col = _columns[_resizingColumn];
        col.width = newWidth;

        if ([_delegate respondsToSelector:@selector(headerBar:didResizeColumn:toWidth:)]) {
            [_delegate headerBar:self didResizeColumn:_resizingColumn toWidth:newWidth];
        }

        [self setNeedsDisplay:YES];

    } else if (_draggingColumn >= 0) {
        // Dragging column for reorder
        CGFloat dragDelta = location.x - ([self xOffsetForColumn:_draggingColumn]);
        _dragStartX = [self xOffsetForColumn:_draggingColumn] + _scrollOffset + dragDelta;

        // Calculate drop target
        _dropTargetIndex = [self columnAtX:location.x];
        if (_dropTargetIndex < 0) {
            // Off the end
            if (location.x > [self xOffsetForColumn:_columns.count - 1]) {
                _dropTargetIndex = _columns.count;
            } else {
                _dropTargetIndex = 0;
            }
        }

        [self setNeedsDisplay:YES];
    }
}

- (void)mouseUp:(NSEvent *)event {
    NSPoint location = [self convertPoint:event.locationInWindow fromView:nil];

    if (_resizingColumn == -2) {
        // Finished resizing group column
        [NSCursor pop];

        if ([_delegate respondsToSelector:@selector(headerBar:didFinishResizingGroupColumn:)]) {
            [_delegate headerBar:self didFinishResizingGroupColumn:_groupColumnWidth];
        }

        _resizingColumn = -1;

    } else if (_resizingColumn >= 0) {
        [NSCursor pop];

        if ([_delegate respondsToSelector:@selector(headerBar:didFinishResizingColumn:)]) {
            [_delegate headerBar:self didFinishResizingColumn:_resizingColumn];
        }

        _resizingColumn = -1;

    } else if (_draggingColumn >= 0) {
        if (_dropTargetIndex >= 0 && _dropTargetIndex != _draggingColumn &&
            _dropTargetIndex != _draggingColumn + 1) {
            // Reorder columns
            if ([_delegate respondsToSelector:@selector(headerBar:didReorderColumnFrom:to:)]) {
                [_delegate headerBar:self didReorderColumnFrom:_draggingColumn to:_dropTargetIndex];
            }
        } else {
            // Just a click, not a drag
            NSInteger clickedColumn = [self columnAtX:location.x];
            if (clickedColumn >= 0 && clickedColumn == _draggingColumn) {
                if ([_delegate respondsToSelector:@selector(headerBar:didClickColumn:)]) {
                    [_delegate headerBar:self didClickColumn:clickedColumn];
                }
            }
        }

        _draggingColumn = -1;
        _dropTargetIndex = -1;
        [self setNeedsDisplay:YES];
    }
}

- (void)rightMouseDown:(NSEvent *)event {
    NSPoint windowPoint = event.locationInWindow;
    NSPoint screenPoint = [[self window] convertPointToScreen:windowPoint];

    if ([_delegate respondsToSelector:@selector(headerBar:showColumnMenuAtPoint:)]) {
        [_delegate headerBar:self showColumnMenuAtPoint:screenPoint];
    }
}

- (void)mouseMoved:(NSEvent *)event {
    NSPoint location = [self convertPoint:event.locationInWindow fromView:nil];

    // Update cursor for resize handles
    NSInteger resizeHandle = [self resizeHandleAtX:location.x];
    if (resizeHandle == -2 || resizeHandle >= 0) {
        [[NSCursor resizeLeftRightCursor] set];
    } else {
        [[NSCursor arrowCursor] set];
    }

    // Update hovered column
    NSInteger newHovered = [self columnAtX:location.x];
    if (newHovered != _hoveredColumn) {
        _hoveredColumn = newHovered;
        [self setNeedsDisplay:YES];
    }
}

- (void)mouseExited:(NSEvent *)event {
    [[NSCursor arrowCursor] set];
    if (_hoveredColumn >= 0) {
        _hoveredColumn = -1;
        [self setNeedsDisplay:YES];
    }
}

- (void)resetCursorRects {
    [super resetCursorRects];

    // Group column resize handle
    if (_groupColumnWidth > 0) {
        NSRect groupHandleRect = NSMakeRect(_groupColumnWidth - kResizeHandleWidth / 2, 0,
                                            kResizeHandleWidth, getHeaderHeight());
        [self addCursorRect:groupHandleRect cursor:[NSCursor resizeLeftRightCursor]];
    }

    CGFloat x = _groupColumnWidth - _scrollOffset;

    for (NSInteger i = 0; i < (NSInteger)_columns.count; i++) {
        CGFloat colWidth = _columns[i].width;
        NSRect handleRect = NSMakeRect(x + colWidth - kResizeHandleWidth / 2, 0,
                                       kResizeHandleWidth, getHeaderHeight());
        [self addCursorRect:handleRect cursor:[NSCursor resizeLeftRightCursor]];
        x += colWidth;
    }
}

@end
