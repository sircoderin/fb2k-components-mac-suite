#import "EffectConfigBase.h"
#import "ParameterSlider.h"
#include "Effects/WahWah.h"

@interface WahWahConfigView : EffectConfigBase {
    ParameterSlider *_rateSlider;
    ParameterSlider *_depthSlider;
    ParameterSlider *_resonanceSlider;
    ParameterSlider *_centerFreqSlider;
    ParameterSlider *_freqRangeSlider;
}
@end

@implementation WahWahConfigView

- (void)viewDidLoad {
    [super viewDidLoad];

    dsp_preset_impl preset;
    self.callback->get_preset(preset);
    auto params = effects_dsp::wahwah_common::parse_preset(preset);

    __weak typeof(self) weakSelf = self;
    auto onChange = ^(float) { [weakSelf pushPreset]; };

    _rateSlider = [self addSliderWithLabel:@"Rate (Hz)"
                                  minValue:0.1f maxValue:10.0f
                                     value:params.rate
                              formatString:@"%.2f" onChange:onChange];

    _depthSlider = [self addSliderWithLabel:@"Depth"
                                   minValue:0.0f maxValue:1.0f
                                      value:params.depth
                               formatString:@"%.2f" onChange:onChange];

    _resonanceSlider = [self addSliderWithLabel:@"Resonance"
                                       minValue:0.5f maxValue:10.0f
                                          value:params.resonance
                                   formatString:@"%.1f" onChange:onChange];

    _centerFreqSlider = [self addSliderWithLabel:@"Center Freq (Hz)"
                                        minValue:200.0f maxValue:5000.0f
                                           value:params.center_freq
                                    formatString:@"%.0f" onChange:onChange];

    _freqRangeSlider = [self addSliderWithLabel:@"Freq Range (Hz)"
                                       minValue:100.0f maxValue:3000.0f
                                          value:params.freq_range
                                   formatString:@"%.0f" onChange:onChange];
}

- (void)pushPreset {
    effects_dsp::wahwah_common::Params p;
    p.rate = _rateSlider.value;
    p.depth = _depthSlider.value;
    p.resonance = _resonanceSlider.value;
    p.center_freq = _centerFreqSlider.value;
    p.freq_range = _freqRangeSlider.value;

    dsp_preset_impl preset;
    effects_dsp::wahwah_common::make_preset(p, preset);
    self.callback->set_preset(preset);
}

@end

service_ptr ConfigureWahWahDSP(fb2k::hwnd_t parent,
                                dsp_preset_edit_callback_v2::ptr callback) {
    WahWahConfigView* view = [WahWahConfigView new];
    view.callback = callback;
    return fb2k::wrapNSObject(view);
}
