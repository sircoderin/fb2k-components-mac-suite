#pragma once

#ifdef __OBJC__
#import <Cocoa/Cocoa.h>
#include <foobar2000/SDK/dsp.h>

@class ParameterSlider;

// Base NSViewController for effect configuration popups.
// Subclasses add ParameterSlider rows in -setupParameters and push
// preset changes by calling -notifyPresetChanged.
@interface EffectConfigBase : NSViewController

@property (nonatomic) dsp_preset_edit_callback_v2::ptr callback;
@property (nonatomic, readonly) NSStackView *stackView;

// Add a slider row to the stack. Returns the created slider for binding.
- (ParameterSlider *)addSliderWithLabel:(NSString *)label
                               minValue:(float)min
                               maxValue:(float)max
                                  value:(float)value
                           formatString:(NSString *)format
                               onChange:(void (^)(float))onChange;

// Add an arbitrary view (e.g., popup button row) to the stack.
- (void)addView:(NSView *)view;

@end

#endif
