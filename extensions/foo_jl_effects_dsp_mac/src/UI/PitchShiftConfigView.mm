#import "EffectConfigBase.h"
#import "ParameterSlider.h"
#include "Effects/PitchShift.h"

@interface PitchShiftConfigView : EffectConfigBase {
    ParameterSlider *_pitchSlider;
}
@end

@implementation PitchShiftConfigView

- (void)viewDidLoad {
    [super viewDidLoad];

    dsp_preset_impl preset;
    self.callback->get_preset(preset);
    auto params = effects_dsp::pitchshift_common::parse_preset(preset);

    __weak typeof(self) weakSelf = self;
    auto onChange = ^(float) { [weakSelf pushPreset]; };

    _pitchSlider = [self addSliderWithLabel:@"Pitch (semitones)"
                                   minValue:-12.0f maxValue:12.0f
                                      value:params.pitch_semitones
                               formatString:@"%.1f" onChange:onChange];
}

- (void)pushPreset {
    effects_dsp::pitchshift_common::Params p;
    p.pitch_semitones = _pitchSlider.value;

    dsp_preset_impl preset;
    effects_dsp::pitchshift_common::make_preset(p, preset);
    self.callback->set_preset(preset);
}

@end

service_ptr ConfigurePitchShiftDSP(fb2k::hwnd_t parent,
                                    dsp_preset_edit_callback_v2::ptr callback) {
    PitchShiftConfigView* view = [PitchShiftConfigView new];
    view.callback = callback;
    return fb2k::wrapNSObject(view);
}
