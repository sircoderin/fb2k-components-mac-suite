//
//  QueueHeaderView.mm
//  foo_jl_queue_manager
//
//  Simple custom header bar (like SimPlaylist's) - NOT an NSTableHeaderView
//

#import "QueueHeaderView.h"
#import "../../../../shared/UIStyles.h"

static const CGFloat kHeaderHeight = 22.0;
static const CGFloat kTextPadding = 6.0;

@implementation QueueHeaderView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _indexColumnWidth = 30;
        _titleColumnWidth = 200;
        _durationColumnWidth = 60;
    }
    return self;
}

- (BOOL)isFlipped {
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    // Background - use windowBackgroundColor like SimPlaylist
    [[NSColor windowBackgroundColor] setFill];
    NSRectFill(self.bounds);

    // Draw column headers
    CGFloat x = 0;

    // Column 1: #
    [self drawHeaderCell:@"#" inRect:NSMakeRect(x, 0, _indexColumnWidth, kHeaderHeight)];
    x += _indexColumnWidth;

    // Column 2: Artist - Title
    [self drawHeaderCell:@"Artist - Title" inRect:NSMakeRect(x, 0, _titleColumnWidth, kHeaderHeight)];
    x += _titleColumnWidth;

    // Column 3: Duration
    [self drawHeaderCell:@"Duration" inRect:NSMakeRect(x, 0, _durationColumnWidth, kHeaderHeight)];

    // Bottom border
    [[NSColor separatorColor] setFill];
    NSRectFill(NSMakeRect(0, kHeaderHeight - 1, self.bounds.size.width, 1));
}

- (void)drawHeaderCell:(NSString *)title inRect:(NSRect)rect {
    // Draw right separator (column divider) - short, with padding
    [[NSColor separatorColor] setFill];
    NSRectFill(NSMakeRect(NSMaxX(rect) - 1, 4, 1, rect.size.height - 8));

    // Draw text
    NSRect textRect = NSInsetRect(rect, kTextPadding, 2);

    NSDictionary *attrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:11 weight:NSFontWeightMedium],
        NSForegroundColorAttributeName: [NSColor secondaryLabelColor]
    };

    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineBreakMode = NSLineBreakByTruncatingTail;

    NSMutableDictionary *attrsCopy = [attrs mutableCopy];
    attrsCopy[NSParagraphStyleAttributeName] = style;

    [title drawInRect:textRect withAttributes:attrsCopy];
}

@end
