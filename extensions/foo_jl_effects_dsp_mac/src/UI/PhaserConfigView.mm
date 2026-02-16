#import "EffectConfigBase.h"
#import "ParameterSlider.h"
#include "Effects/Phaser.h"

@interface PhaserConfigView : EffectConfigBase {
    ParameterSlider *_rateSlider;
    ParameterSlider *_depthSlider;
    ParameterSlider *_feedbackSlider;
    ParameterSlider *_stagesSlider;
    ParameterSlider *_wetDrySlider;
}
@end

@implementation PhaserConfigView

- (void)viewDidLoad {
    [super viewDidLoad];

    dsp_preset_impl preset;
    self.callback->get_preset(preset);
    auto params = effects_dsp::phaser_common::parse_preset(preset);

    __weak typeof(self) weakSelf = self;
    auto onChange = ^(float) { [weakSelf pushPreset]; };

    _rateSlider = [self addSliderWithLabel:@"Rate (Hz)"
                                  minValue:0.05f maxValue:5.0f
                                     value:params.rate
                              formatString:@"%.2f" onChange:onChange];

    _depthSlider = [self addSliderWithLabel:@"Depth"
                                   minValue:0.0f maxValue:1.0f
                                      value:params.depth
                               formatString:@"%.2f" onChange:onChange];

    _feedbackSlider = [self addSliderWithLabel:@"Feedback"
                                      minValue:0.0f maxValue:0.99f
                                         value:params.feedback
                                  formatString:@"%.2f" onChange:onChange];

    _stagesSlider = [self addSliderWithLabel:@"Stages"
                                    minValue:2.0f maxValue:12.0f
                                       value:(float)params.stages
                                formatString:@"%.0f" onChange:onChange];

    _wetDrySlider = [self addSliderWithLabel:@"Wet/Dry Mix"
                                    minValue:0.0f maxValue:1.0f
                                       value:params.wet_dry
                                formatString:@"%.2f" onChange:onChange];
}

- (void)pushPreset {
    effects_dsp::phaser_common::Params p;
    p.rate = _rateSlider.value;
    p.depth = _depthSlider.value;
    p.feedback = _feedbackSlider.value;
    p.stages = (int32_t)roundf(_stagesSlider.value);
    p.wet_dry = _wetDrySlider.value;

    dsp_preset_impl preset;
    effects_dsp::phaser_common::make_preset(p, preset);
    self.callback->set_preset(preset);
}

@end

service_ptr ConfigurePhaserDSP(fb2k::hwnd_t parent,
                                dsp_preset_edit_callback_v2::ptr callback) {
    PhaserConfigView* view = [PhaserConfigView new];
    view.callback = callback;
    return fb2k::wrapNSObject(view);
}
