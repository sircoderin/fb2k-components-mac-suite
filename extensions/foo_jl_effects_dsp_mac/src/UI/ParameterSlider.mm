#import "ParameterSlider.h"

static const CGFloat kLabelWidth = 100.0;
static const CGFloat kValueWidth = 70.0;
static const CGFloat kRowHeight = 24.0;
static const CGFloat kSpacing = 8.0;

@interface ParameterSlider ()
@property (nonatomic, strong) NSTextField *labelField;
@property (nonatomic, strong) NSSlider *slider;
@property (nonatomic, strong) NSTextField *valueField;
@property (nonatomic, copy) NSString *formatString;
@end

@implementation ParameterSlider

+ (instancetype)sliderWithLabel:(NSString *)label
                       minValue:(float)min
                       maxValue:(float)max
                          value:(float)value
                   formatString:(NSString *)format
                       onChange:(void (^)(float))onChange {
    ParameterSlider *ps = [[ParameterSlider alloc] initWithFrame:NSZeroRect];
    ps->_label = [label copy];
    ps->_minValue = min;
    ps->_maxValue = max;
    ps->_formatString = [format copy] ?: @"%.2f";
    ps.onValueChanged = onChange;
    [ps setupUI];
    ps.value = value;
    return ps;
}

- (void)setupUI {
    self.translatesAutoresizingMaskIntoConstraints = NO;

    // Label
    _labelField = [NSTextField labelWithString:_label];
    _labelField.translatesAutoresizingMaskIntoConstraints = NO;
    _labelField.font = [NSFont systemFontOfSize:12];
    _labelField.alignment = NSTextAlignmentRight;
    [self addSubview:_labelField];

    // Slider
    _slider = [NSSlider sliderWithValue:(_minValue + _maxValue) / 2.0
                               minValue:_minValue
                               maxValue:_maxValue
                                 target:self
                                 action:@selector(sliderChanged:)];
    _slider.translatesAutoresizingMaskIntoConstraints = NO;
    _slider.continuous = YES;
    [self addSubview:_slider];

    // Value text field
    _valueField = [[NSTextField alloc] initWithFrame:NSZeroRect];
    _valueField.translatesAutoresizingMaskIntoConstraints = NO;
    _valueField.font = [NSFont monospacedDigitSystemFontOfSize:11 weight:NSFontWeightRegular];
    _valueField.alignment = NSTextAlignmentCenter;
    _valueField.editable = YES;
    _valueField.bordered = YES;
    _valueField.bezeled = YES;
    _valueField.bezelStyle = NSTextFieldSquareBezel;
    _valueField.target = self;
    _valueField.action = @selector(textFieldChanged:);
    _valueField.delegate = (id<NSTextFieldDelegate>)self;
    [self addSubview:_valueField];

    // Layout
    [NSLayoutConstraint activateConstraints:@[
        [self.heightAnchor constraintEqualToConstant:kRowHeight],
        [_labelField.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_labelField.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [_labelField.widthAnchor constraintEqualToConstant:kLabelWidth],
        [_slider.leadingAnchor constraintEqualToAnchor:_labelField.trailingAnchor constant:kSpacing],
        [_slider.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [_valueField.leadingAnchor constraintEqualToAnchor:_slider.trailingAnchor constant:kSpacing],
        [_valueField.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_valueField.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [_valueField.widthAnchor constraintEqualToConstant:kValueWidth],
    ]];
}

- (void)setValue:(float)value {
    _value = value;
    _slider.floatValue = value;
    _valueField.stringValue = [NSString stringWithFormat:_formatString, value];
}

- (void)sliderChanged:(NSSlider *)sender {
    _value = sender.floatValue;
    _valueField.stringValue = [NSString stringWithFormat:_formatString, _value];
    if (_onValueChanged) _onValueChanged(_value);
}

- (void)textFieldChanged:(NSTextField *)sender {
    float v = sender.floatValue;
    v = fmaxf(_minValue, fminf(_maxValue, v));
    self.value = v;
    if (_onValueChanged) _onValueChanged(_value);
}

@end
