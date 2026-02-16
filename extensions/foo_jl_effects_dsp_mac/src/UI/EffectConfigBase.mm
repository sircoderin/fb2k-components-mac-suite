#import "EffectConfigBase.h"
#import "ParameterSlider.h"

static const CGFloat kViewWidth = 400.0;
static const CGFloat kPadding = 16.0;
static const CGFloat kStackSpacing = 10.0;

@implementation EffectConfigBase

- (void)loadView {
    NSView *container = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, kViewWidth, 100)];

    _stackView = [[NSStackView alloc] initWithFrame:NSZeroRect];
    _stackView.translatesAutoresizingMaskIntoConstraints = NO;
    _stackView.orientation = NSUserInterfaceLayoutOrientationVertical;
    _stackView.alignment = NSLayoutAttributeLeading;
    _stackView.spacing = kStackSpacing;
    _stackView.edgeInsets = NSEdgeInsetsMake(kPadding, kPadding, kPadding, kPadding);
    [container addSubview:_stackView];

    [NSLayoutConstraint activateConstraints:@[
        [_stackView.topAnchor constraintEqualToAnchor:container.topAnchor],
        [_stackView.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
        [_stackView.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
        [_stackView.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],
    ]];

    self.view = container;
}

- (ParameterSlider *)addSliderWithLabel:(NSString *)label
                               minValue:(float)min
                               maxValue:(float)max
                                  value:(float)value
                           formatString:(NSString *)format
                               onChange:(void (^)(float))onChange {
    ParameterSlider *slider = [ParameterSlider sliderWithLabel:label
                                                      minValue:min
                                                      maxValue:max
                                                         value:value
                                                  formatString:format
                                                      onChange:onChange];
    [_stackView addArrangedSubview:slider];
    [slider.widthAnchor constraintEqualToAnchor:_stackView.widthAnchor
                                       constant:-(kPadding * 2)].active = YES;
    return slider;
}

- (void)addView:(NSView *)view {
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [_stackView addArrangedSubview:view];
    [view.widthAnchor constraintEqualToAnchor:_stackView.widthAnchor
                                     constant:-(kPadding * 2)].active = YES;
}

@end
