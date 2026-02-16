#import "EffectConfigBase.h"
#import "ParameterSlider.h"
#include "Effects/Chorus.h"

@interface ChorusConfigView : EffectConfigBase {
    ParameterSlider *_delaySlider;
    ParameterSlider *_rateSlider;
    ParameterSlider *_depthSlider;
    ParameterSlider *_feedbackSlider;
    ParameterSlider *_wetDrySlider;
}
@end

@implementation ChorusConfigView

- (void)viewDidLoad {
    [super viewDidLoad];

    dsp_preset_impl preset;
    self.callback->get_preset(preset);
    auto params = effects_dsp::chorus_common::parse_preset(preset);

    __weak typeof(self) weakSelf = self;
    auto onChange = ^(float) { [weakSelf pushPreset]; };

    _delaySlider = [self addSliderWithLabel:@"Delay (ms)"
                                   minValue:1.0f maxValue:50.0f
                                      value:params.delay_ms
                               formatString:@"%.1f" onChange:onChange];

    _rateSlider = [self addSliderWithLabel:@"Rate (Hz)"
                                  minValue:0.05f maxValue:5.0f
                                     value:params.rate
                              formatString:@"%.2f" onChange:onChange];

    _depthSlider = [self addSliderWithLabel:@"Depth"
                                   minValue:0.0f maxValue:1.0f
                                      value:params.depth
                               formatString:@"%.2f" onChange:onChange];

    _feedbackSlider = [self addSliderWithLabel:@"Feedback"
                                      minValue:0.0f maxValue:0.95f
                                         value:params.feedback
                                  formatString:@"%.2f" onChange:onChange];

    _wetDrySlider = [self addSliderWithLabel:@"Wet/Dry Mix"
                                    minValue:0.0f maxValue:1.0f
                                       value:params.wet_dry
                                formatString:@"%.2f" onChange:onChange];
}

- (void)pushPreset {
    effects_dsp::chorus_common::Params p;
    p.delay_ms = _delaySlider.value;
    p.rate = _rateSlider.value;
    p.depth = _depthSlider.value;
    p.feedback = _feedbackSlider.value;
    p.wet_dry = _wetDrySlider.value;

    dsp_preset_impl preset;
    effects_dsp::chorus_common::make_preset(p, preset);
    self.callback->set_preset(preset);
}

@end

service_ptr ConfigureChorusDSP(fb2k::hwnd_t parent,
                                dsp_preset_edit_callback_v2::ptr callback) {
    ChorusConfigView* view = [ChorusConfigView new];
    view.callback = callback;
    return fb2k::wrapNSObject(view);
}
