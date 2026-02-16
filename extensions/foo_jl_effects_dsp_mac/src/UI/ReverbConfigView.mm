#import "EffectConfigBase.h"
#import "ParameterSlider.h"
#include "Effects/Reverb.h"

@interface ReverbConfigView : EffectConfigBase {
    ParameterSlider *_roomSizeSlider;
    ParameterSlider *_dampingSlider;
    ParameterSlider *_wetSlider;
    ParameterSlider *_drySlider;
    ParameterSlider *_widthSlider;
}
@end

@implementation ReverbConfigView

- (void)viewDidLoad {
    [super viewDidLoad];

    dsp_preset_impl preset;
    self.callback->get_preset(preset);
    auto params = effects_dsp::reverb_common::parse_preset(preset);

    __weak typeof(self) weakSelf = self;
    auto onChange = ^(float) { [weakSelf pushPreset]; };

    _roomSizeSlider = [self addSliderWithLabel:@"Room Size"
                                      minValue:0.0f maxValue:1.0f
                                         value:params.room_size
                                  formatString:@"%.2f" onChange:onChange];

    _dampingSlider = [self addSliderWithLabel:@"Damping"
                                     minValue:0.0f maxValue:1.0f
                                        value:params.damping
                                 formatString:@"%.2f" onChange:onChange];

    _wetSlider = [self addSliderWithLabel:@"Wet Level"
                                 minValue:0.0f maxValue:1.0f
                                    value:params.wet
                             formatString:@"%.2f" onChange:onChange];

    _drySlider = [self addSliderWithLabel:@"Dry Level"
                                 minValue:0.0f maxValue:1.0f
                                    value:params.dry
                             formatString:@"%.2f" onChange:onChange];

    _widthSlider = [self addSliderWithLabel:@"Stereo Width"
                                   minValue:0.0f maxValue:1.0f
                                      value:params.width
                               formatString:@"%.2f" onChange:onChange];
}

- (void)pushPreset {
    effects_dsp::reverb_common::Params p;
    p.room_size = _roomSizeSlider.value;
    p.damping = _dampingSlider.value;
    p.wet = _wetSlider.value;
    p.dry = _drySlider.value;
    p.width = _widthSlider.value;

    dsp_preset_impl preset;
    effects_dsp::reverb_common::make_preset(p, preset);
    self.callback->set_preset(preset);
}

@end

service_ptr ConfigureReverbDSP(fb2k::hwnd_t parent,
                                dsp_preset_edit_callback_v2::ptr callback) {
    ReverbConfigView* view = [ReverbConfigView new];
    view.callback = callback;
    return fb2k::wrapNSObject(view);
}
