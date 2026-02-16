#import "EffectConfigBase.h"
#import "ParameterSlider.h"
#include "Effects/Vibrato.h"

@interface VibratoConfigView : EffectConfigBase {
    ParameterSlider *_rateSlider;
    ParameterSlider *_depthSlider;
}
@end

@implementation VibratoConfigView

- (void)viewDidLoad {
    [super viewDidLoad];

    dsp_preset_impl preset;
    self.callback->get_preset(preset);
    auto params = effects_dsp::vibrato_common::parse_preset(preset);

    __weak typeof(self) weakSelf = self;
    auto onChange = ^(float) { [weakSelf pushPreset]; };

    _rateSlider = [self addSliderWithLabel:@"Rate (Hz)"
                                  minValue:0.1f maxValue:14.0f
                                     value:params.rate
                              formatString:@"%.1f" onChange:onChange];

    _depthSlider = [self addSliderWithLabel:@"Depth"
                                   minValue:0.0f maxValue:1.0f
                                      value:params.depth
                               formatString:@"%.2f" onChange:onChange];
}

- (void)pushPreset {
    effects_dsp::vibrato_common::Params p;
    p.rate = _rateSlider.value;
    p.depth = _depthSlider.value;

    dsp_preset_impl preset;
    effects_dsp::vibrato_common::make_preset(p, preset);
    self.callback->set_preset(preset);
}

@end

service_ptr ConfigureVibratoDSP(fb2k::hwnd_t parent,
                                 dsp_preset_edit_callback_v2::ptr callback) {
    VibratoConfigView* view = [VibratoConfigView new];
    view.callback = callback;
    return fb2k::wrapNSObject(view);
}
