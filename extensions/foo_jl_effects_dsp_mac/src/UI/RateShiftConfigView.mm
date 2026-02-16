#import "EffectConfigBase.h"
#import "ParameterSlider.h"
#include "Effects/RateShift.h"

@interface RateShiftConfigView : EffectConfigBase {
    ParameterSlider *_rateSlider;
}
@end

@implementation RateShiftConfigView

- (void)viewDidLoad {
    [super viewDidLoad];

    dsp_preset_impl preset;
    self.callback->get_preset(preset);
    auto params = effects_dsp::rateshift_common::parse_preset(preset);

    __weak typeof(self) weakSelf = self;
    auto onChange = ^(float) { [weakSelf pushPreset]; };

    _rateSlider = [self addSliderWithLabel:@"Rate (%)"
                                  minValue:-50.0f maxValue:100.0f
                                     value:params.rate_pct
                              formatString:@"%.1f" onChange:onChange];
}

- (void)pushPreset {
    effects_dsp::rateshift_common::Params p;
    p.rate_pct = _rateSlider.value;

    dsp_preset_impl preset;
    effects_dsp::rateshift_common::make_preset(p, preset);
    self.callback->set_preset(preset);
}

@end

service_ptr ConfigureRateShiftDSP(fb2k::hwnd_t parent,
                                   dsp_preset_edit_callback_v2::ptr callback) {
    RateShiftConfigView* view = [RateShiftConfigView new];
    view.callback = callback;
    return fb2k::wrapNSObject(view);
}
