//
//  QueueHeaderView.mm
//  foo_jl_queue_manager
//
//  Simple custom header bar (like SimPlaylist's) - NOT an NSTableHeaderView
//  Uses shared UIStyles.h for consistent appearance with SimPlaylist
//

#import "QueueHeaderView.h"
#import "../../../../shared/UIStyles.h"

@implementation QueueHeaderView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _indexColumnWidth = 30;
        _titleColumnWidth = 200;
        _durationColumnWidth = 60;
        _glassBackground = NO;
    }
    return self;
}

- (BOOL)isFlipped {
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    CGFloat height = fb2k_ui::headerHeight(fb2k_ui::SizeVariant::Compact);

    // Background - use glass-aware helper
    NSColor *bgColor = _glassBackground
        ? fb2k_ui::headerBackgroundColorForGlass(fb2k_ui::AccentMode::None)
        : fb2k_ui::headerBackgroundColor(fb2k_ui::AccentMode::None);

    if (bgColor) {
        [bgColor setFill];
        NSRectFill(self.bounds);
    }

    // Top highlight (subtle gradient effect) - only for non-glass
    NSColor *highlightColor = _glassBackground
        ? fb2k_ui::headerTopHighlightColorForGlass(fb2k_ui::AccentMode::None)
        : fb2k_ui::headerTopHighlightColor(fb2k_ui::AccentMode::None);

    if (highlightColor) {
        [highlightColor setFill];
        NSRectFill(NSMakeRect(0, 0, self.bounds.size.width, 1));
    }

    // Draw column headers
    CGFloat x = 0;

    // Column 1: #
    [self drawHeaderCell:@"#" inRect:NSMakeRect(x, 0, _indexColumnWidth, height)];
    x += _indexColumnWidth;

    // Column 2: Artist - Title
    [self drawHeaderCell:@"Artist - Title" inRect:NSMakeRect(x, 0, _titleColumnWidth, height)];
    x += _titleColumnWidth;

    // Column 3: Duration
    [self drawHeaderCell:@"Duration" inRect:NSMakeRect(x, 0, _durationColumnWidth, height)];

    // Bottom border
    [fb2k_ui::headerBottomBorderColor() setFill];
    NSRectFill(NSMakeRect(0, height - 1, self.bounds.size.width, 1));
}

- (void)drawHeaderCell:(NSString *)title inRect:(NSRect)rect {
    // Draw right separator (column divider) - short, with padding
    [fb2k_ui::headerDividerColor() setFill];
    NSRectFill(NSMakeRect(NSMaxX(rect) - 1, 4, 1, rect.size.height - 8));

    // Draw text
    NSRect textRect = NSInsetRect(rect, fb2k_ui::kHeaderTextPadding, 2);

    NSDictionary *attrs = @{
        NSFontAttributeName: fb2k_ui::headerFont(fb2k_ui::SizeVariant::Compact),
        NSForegroundColorAttributeName: fb2k_ui::headerTextColor()
    };

    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineBreakMode = NSLineBreakByTruncatingTail;

    NSMutableDictionary *attrsCopy = [attrs mutableCopy];
    attrsCopy[NSParagraphStyleAttributeName] = style;

    [title drawInRect:textRect withAttributes:attrsCopy];
}

@end
