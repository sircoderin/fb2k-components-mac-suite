#import "EffectConfigBase.h"
#import "ParameterSlider.h"
#include "Effects/Tremolo.h"

@interface TremoloConfigView : EffectConfigBase {
    ParameterSlider *_freqSlider;
    ParameterSlider *_depthSlider;
}
@end

@implementation TremoloConfigView

- (void)viewDidLoad {
    [super viewDidLoad];

    dsp_preset_impl preset;
    self.callback->get_preset(preset);
    auto params = effects_dsp::tremolo_common::parse_preset(preset);

    __weak typeof(self) weakSelf = self;
    auto onChange = ^(float) { [weakSelf pushPreset]; };

    _freqSlider = [self addSliderWithLabel:@"Rate (Hz)"
                                  minValue:0.1f maxValue:20.0f
                                     value:params.freq
                              formatString:@"%.1f" onChange:onChange];

    _depthSlider = [self addSliderWithLabel:@"Depth"
                                   minValue:0.0f maxValue:1.0f
                                      value:params.depth
                               formatString:@"%.2f" onChange:onChange];
}

- (void)pushPreset {
    effects_dsp::tremolo_common::Params p;
    p.freq = _freqSlider.value;
    p.depth = _depthSlider.value;

    dsp_preset_impl preset;
    effects_dsp::tremolo_common::make_preset(p, preset);
    self.callback->set_preset(preset);
}

@end

service_ptr ConfigureTremoloDSP(fb2k::hwnd_t parent,
                                 dsp_preset_edit_callback_v2::ptr callback) {
    TremoloConfigView* view = [TremoloConfigView new];
    view.callback = callback;
    return fb2k::wrapNSObject(view);
}
