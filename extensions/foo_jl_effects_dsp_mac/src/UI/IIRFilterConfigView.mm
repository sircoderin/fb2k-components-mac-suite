#import "EffectConfigBase.h"
#import "ParameterSlider.h"
#include "Effects/IIRFilter.h"
#include "Core/BiquadFilter.h"

static const CGFloat kLabelWidth = 100.0;

@interface IIRFilterConfigView : EffectConfigBase {
    NSPopUpButton *_typePopup;
    ParameterSlider *_freqSlider;
    ParameterSlider *_qSlider;
    ParameterSlider *_gainSlider;
}
@end

@implementation IIRFilterConfigView

- (void)viewDidLoad {
    [super viewDidLoad];

    dsp_preset_impl preset;
    self.callback->get_preset(preset);
    auto params = effects_dsp::iir_filter_common::parse_preset(preset);

    // Filter type picker row
    NSView *typeRow = [[NSView alloc] initWithFrame:NSZeroRect];
    typeRow.translatesAutoresizingMaskIntoConstraints = NO;

    NSTextField *typeLabel = [NSTextField labelWithString:@"Filter Type"];
    typeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    typeLabel.font = [NSFont systemFontOfSize:12];
    typeLabel.alignment = NSTextAlignmentRight;
    [typeRow addSubview:typeLabel];

    _typePopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
    _typePopup.translatesAutoresizingMaskIntoConstraints = NO;
    _typePopup.font = [NSFont systemFontOfSize:12];
    for (int i = 0; i < static_cast<int>(effects_dsp::BiquadType::Count); ++i) {
        [_typePopup addItemWithTitle:@(effects_dsp::biquad_type_names[i])];
    }
    [_typePopup selectItemAtIndex:params.filter_type];
    _typePopup.target = self;
    _typePopup.action = @selector(typeChanged:);
    [typeRow addSubview:_typePopup];

    [NSLayoutConstraint activateConstraints:@[
        [typeRow.heightAnchor constraintEqualToConstant:26],
        [typeLabel.leadingAnchor constraintEqualToAnchor:typeRow.leadingAnchor],
        [typeLabel.centerYAnchor constraintEqualToAnchor:typeRow.centerYAnchor],
        [typeLabel.widthAnchor constraintEqualToConstant:kLabelWidth],
        [_typePopup.leadingAnchor constraintEqualToAnchor:typeLabel.trailingAnchor constant:8],
        [_typePopup.trailingAnchor constraintEqualToAnchor:typeRow.trailingAnchor],
        [_typePopup.centerYAnchor constraintEqualToAnchor:typeRow.centerYAnchor],
    ]];
    [self addView:typeRow];

    // Parameter sliders
    __weak typeof(self) weakSelf = self;
    auto onChange = ^(float) { [weakSelf pushPreset]; };

    _freqSlider = [self addSliderWithLabel:@"Frequency (Hz)"
                                  minValue:20.0f maxValue:20000.0f
                                     value:params.freq
                              formatString:@"%.0f" onChange:onChange];

    _qSlider = [self addSliderWithLabel:@"Q / Bandwidth"
                               minValue:0.01f maxValue:100.0f
                                  value:params.q
                           formatString:@"%.3f" onChange:onChange];

    _gainSlider = [self addSliderWithLabel:@"Gain (dB)"
                                  minValue:-30.0f maxValue:30.0f
                                     value:params.gain_db
                              formatString:@"%.1f" onChange:onChange];

    [self updateGainEnabled];
}

- (void)typeChanged:(NSPopUpButton *)sender {
    [self updateGainEnabled];
    [self pushPreset];
}

- (void)updateGainEnabled {
    auto type = static_cast<effects_dsp::BiquadType>(_typePopup.indexOfSelectedItem);
    BOOL enabled = effects_dsp::biquad_type_uses_gain(type);
    _gainSlider.alphaValue = enabled ? 1.0 : 0.4;
    // Slider still works but visually indicates relevance
}

- (void)pushPreset {
    effects_dsp::iir_filter_common::Params p;
    p.filter_type = static_cast<int32_t>(_typePopup.indexOfSelectedItem);
    p.freq = _freqSlider.value;
    p.q = _qSlider.value;
    p.gain_db = _gainSlider.value;

    dsp_preset_impl preset;
    effects_dsp::iir_filter_common::make_preset(p, preset);
    self.callback->set_preset(preset);
}

@end

service_ptr ConfigureIIRFilterDSP(fb2k::hwnd_t parent,
                                   dsp_preset_edit_callback_v2::ptr callback) {
    IIRFilterConfigView* view = [IIRFilterConfigView new];
    view.callback = callback;
    return fb2k::wrapNSObject(view);
}
