#import "EffectConfigBase.h"
#import "ParameterSlider.h"
#include "Effects/Echo.h"

@interface EchoConfigView : EffectConfigBase {
    ParameterSlider *_delaySlider;
    ParameterSlider *_feedbackSlider;
    ParameterSlider *_wetDrySlider;
}
@end

@implementation EchoConfigView

- (void)viewDidLoad {
    [super viewDidLoad];

    dsp_preset_impl preset;
    self.callback->get_preset(preset);
    auto params = effects_dsp::echo_common::parse_preset(preset);

    __weak typeof(self) weakSelf = self;
    auto onChange = ^(float) { [weakSelf pushPreset]; };

    _delaySlider = [self addSliderWithLabel:@"Delay (ms)"
                                   minValue:1.0f maxValue:5000.0f
                                      value:params.delay_ms
                               formatString:@"%.0f" onChange:onChange];

    _feedbackSlider = [self addSliderWithLabel:@"Feedback"
                                      minValue:0.0f maxValue:1.0f
                                         value:params.feedback
                                  formatString:@"%.2f" onChange:onChange];

    _wetDrySlider = [self addSliderWithLabel:@"Wet/Dry Mix"
                                    minValue:0.0f maxValue:1.0f
                                       value:params.wet_dry
                                formatString:@"%.2f" onChange:onChange];
}

- (void)pushPreset {
    effects_dsp::echo_common::Params p;
    p.delay_ms = _delaySlider.value;
    p.feedback = _feedbackSlider.value;
    p.wet_dry = _wetDrySlider.value;

    dsp_preset_impl preset;
    effects_dsp::echo_common::make_preset(p, preset);
    self.callback->set_preset(preset);
}

@end

service_ptr ConfigureEchoDSP(fb2k::hwnd_t parent,
                              dsp_preset_edit_callback_v2::ptr callback) {
    EchoConfigView* view = [EchoConfigView new];
    view.callback = callback;
    return fb2k::wrapNSObject(view);
}
