#pragma once

#ifdef __OBJC__
#import <Cocoa/Cocoa.h>

// Reusable parameter control row: [Label] [Slider] [Value TextField]
// Laid out horizontally with Auto Layout. Slider sends continuous updates.
@interface ParameterSlider : NSView

@property (nonatomic) float value;
@property (nonatomic, readonly) NSString *label;
@property (nonatomic, readonly) float minValue;
@property (nonatomic, readonly) float maxValue;
@property (nonatomic, copy) void (^onValueChanged)(float newValue);

+ (instancetype)sliderWithLabel:(NSString *)label
                       minValue:(float)min
                       maxValue:(float)max
                          value:(float)value
                   formatString:(NSString *)format
                       onChange:(void (^)(float))onChange;

@end

#endif
