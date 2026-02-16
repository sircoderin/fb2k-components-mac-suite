#import "EffectConfigBase.h"
#import "ParameterSlider.h"
#include "Effects/TempoShift.h"

@interface TempoShiftConfigView : EffectConfigBase {
    ParameterSlider *_tempoSlider;
}
@end

@implementation TempoShiftConfigView

- (void)viewDidLoad {
    [super viewDidLoad];

    dsp_preset_impl preset;
    self.callback->get_preset(preset);
    auto params = effects_dsp::temposhift_common::parse_preset(preset);

    __weak typeof(self) weakSelf = self;
    auto onChange = ^(float) { [weakSelf pushPreset]; };

    _tempoSlider = [self addSliderWithLabel:@"Tempo (%)"
                                   minValue:-50.0f maxValue:100.0f
                                      value:params.tempo_pct
                               formatString:@"%.1f" onChange:onChange];
}

- (void)pushPreset {
    effects_dsp::temposhift_common::Params p;
    p.tempo_pct = _tempoSlider.value;

    dsp_preset_impl preset;
    effects_dsp::temposhift_common::make_preset(p, preset);
    self.callback->set_preset(preset);
}

@end

service_ptr ConfigureTempoShiftDSP(fb2k::hwnd_t parent,
                                    dsp_preset_edit_callback_v2::ptr callback) {
    TempoShiftConfigView* view = [TempoShiftConfigView new];
    view.callback = callback;
    return fb2k::wrapNSObject(view);
}
