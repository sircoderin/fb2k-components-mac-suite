# Effects DSP - Foundation Document

## 1. Project Overview

| Field | Value |
|-------|-------|
| Component | `foo_jl_effects_dsp` |
| Display Name | Effects DSP |
| Platform | macOS (foobar2000 v2.x) |
| SDK | 2025-03-07 |
| Type | DSP (`dsp_impl_base`) |
| License | MIT |
| Version | 1.0.0 |

A collection of 11 real-time audio effects for foobar2000 macOS. This is a macOS port of [`foo_dsp_effect`](https://github.com/mudlord/foo_dsp_effect) by mudlord (Unlicense). The original Windows component provides a set of standard audio effects (echo, reverb, pitch shift, etc.) that are missing from foobar2000's default installation.

Each effect registers as a separate DSP in foobar2000's chain, allowing users to add, remove, and reorder effects independently via Preferences > Playback > DSP Manager.

### Why Port This

- The original `foo_dsp_effect` is Windows-only; macOS users have no equivalent
- All dependencies (SoundTouch, Freeverb, IIR filters) are cross-platform C/C++
- The macOS SDK has full DSP support (`dsp_impl_base`, `dsp_factory_t<>`, config popups)
- Algorithms are well-understood and battle-tested on Windows

---

## 2. The 11 Effects

### Group A: Simple (No Dependencies)

#### Echo
Delay-based effect that repeats the signal after a configurable delay.

- **Algorithm**: Circular buffer with feedback. Each output sample = input + delayed_sample * feedback_gain.
- **Parameters**:
  | Parameter | Range | Default | Unit |
  |-----------|-------|---------|------|
  | Delay | 1 - 5000 | 200 | ms |
  | Feedback | 0.0 - 1.0 | 0.5 | ratio |
  | Wet/Dry Mix | 0.0 - 1.0 | 0.5 | ratio |
- **Buffer**: Pre-allocated circular buffer sized for max delay at max sample rate: `5.0 * 192000 * channels` samples
- **Preset format**: `[delay_ms: float, feedback: float, wet_dry: float]`

#### Tremolo
Amplitude modulation using a low-frequency oscillator.

- **Algorithm**: Output = input * (1.0 - depth * sin(2*pi*freq*t)). Uses an internal phase accumulator, reset on flush.
- **Parameters**:
  | Parameter | Range | Default | Unit |
  |-----------|-------|---------|------|
  | Frequency | 0.1 - 20.0 | 5.0 | Hz |
  | Depth | 0.0 - 1.0 | 0.5 | ratio |
- **Preset format**: `[freq: float, depth: float]`

### Group B: Filter (BiquadFilter Dependency)

#### IIR Filter
Configurable biquad filter with 12 sub-types.

- **Algorithm**: Standard biquad difference equation: `y[n] = (b0*x[n] + b1*x[n-1] + b2*x[n-2] - a1*y[n-1] - a2*y[n-2]) / a0`. Coefficients calculated from Robert Bristow-Johnson's Audio EQ Cookbook formulas.
- **Sub-types**: Lowpass, Highpass, Bandpass (CSG), Bandpass (CZPG), Notch, All-pass, Peaking EQ, Low Shelf, High Shelf, Lowpass (1st order), Highpass (1st order), All-pass (1st order)
- **Parameters**:
  | Parameter | Range | Default | Unit |
  |-----------|-------|---------|------|
  | Filter Type | 0 - 11 | 0 (Lowpass) | enum |
  | Frequency | 20 - 20000 | 1000 | Hz |
  | Q / Bandwidth | 0.01 - 100.0 | 0.707 | Q |
  | Gain | -30.0 - 30.0 | 0.0 | dB |
- **Per-channel state**: Each channel maintains independent `x[n-1], x[n-2], y[n-1], y[n-2]` history
- **Preset format**: `[filter_type: int32, freq: float, q: float, gain_db: float]`

#### Phaser
Multi-stage all-pass filter sweep creating notch/peak comb pattern.

- **Algorithm**: Chain of N all-pass filters with swept center frequency via LFO. Output is mix of dry signal and filtered signal.
- **Parameters**:
  | Parameter | Range | Default | Unit |
  |-----------|-------|---------|------|
  | LFO Rate | 0.05 - 5.0 | 0.5 | Hz |
  | LFO Depth | 0.0 - 1.0 | 0.7 | ratio |
  | Feedback | -0.99 - 0.99 | 0.7 | ratio |
  | Stages | 2 - 12 | 6 | count |
  | Wet/Dry Mix | 0.0 - 1.0 | 0.5 | ratio |
- **Preset format**: `[rate: float, depth: float, feedback: float, stages: int32, wet_dry: float]`

#### WahWah
Auto-wah using a swept bandpass filter controlled by an LFO.

- **Algorithm**: Bandpass filter with center frequency modulated by a triangle or sine LFO. Uses biquad bandpass internally.
- **Parameters**:
  | Parameter | Range | Default | Unit |
  |-----------|-------|---------|------|
  | LFO Rate | 0.1 - 10.0 | 1.5 | Hz |
  | LFO Depth | 0.0 - 1.0 | 0.7 | ratio |
  | Resonance | 0.1 - 10.0 | 2.5 | Q |
  | Center Freq | 300 - 5000 | 700 | Hz |
  | Freq Range | 100 - 4000 | 500 | Hz |
- **Preset format**: `[rate: float, depth: float, resonance: float, center: float, range: float]`

### Group C: Reverb (Freeverb Dependency)

#### Reverb
Room simulation using Freeverb algorithm (Schroeder-Moorer reverb model).

- **Algorithm**: 8 parallel comb filters + 4 series all-pass filters (Freeverb). Stereo processing with tuned delay offsets. The Freeverb implementation is ~200 lines of public-domain C++.
- **Parameters**:
  | Parameter | Range | Default | Unit |
  |-----------|-------|---------|------|
  | Room Size | 0.0 - 1.0 | 0.5 | ratio |
  | Damping | 0.0 - 1.0 | 0.5 | ratio |
  | Wet Level | 0.0 - 1.0 | 0.3 | ratio |
  | Dry Level | 0.0 - 1.0 | 1.0 | ratio |
  | Width | 0.0 - 1.0 | 1.0 | ratio |
- **Channel handling**: Mono input is duplicated to stereo for processing. Multi-channel (>2) processes L/R and passes other channels through.
- **Preset format**: `[room_size: float, damping: float, wet: float, dry: float, width: float]`

### Group D: Modulation (LFO Dependency)

#### Chorus
Multiple delayed copies with LFO-modulated delay times, creating a thickening effect.

- **Algorithm**: N voices, each with a delay line modulated by an LFO at slightly different phases. Output = dry + sum of delayed copies.
- **Parameters**:
  | Parameter | Range | Default | Unit |
  |-----------|-------|---------|------|
  | Delay | 1 - 100 | 20 | ms |
  | LFO Rate | 0.1 - 10.0 | 0.5 | Hz |
  | LFO Depth | 0.0 - 1.0 | 0.5 | ratio |
  | Feedback | 0.0 - 0.95 | 0.0 | ratio |
  | Wet/Dry Mix | 0.0 - 1.0 | 0.5 | ratio |
- **Preset format**: `[delay_ms: float, rate: float, depth: float, feedback: float, wet_dry: float]`

#### Vibrato
Pitch modulation via variable-delay line with LFO.

- **Algorithm**: Single delay line with delay time modulated by LFO. Uses linear interpolation for sub-sample delay values.
- **Parameters**:
  | Parameter | Range | Default | Unit |
  |-----------|-------|---------|------|
  | LFO Rate | 0.1 - 14.0 | 5.0 | Hz |
  | Depth | 0.0 - 1.0 | 0.5 | ratio |
- **Preset format**: `[rate: float, depth: float]`

### Group E: SoundTouch (SoundTouch Library Dependency)

These three effects use the SoundTouch library for time-stretching and pitch-shifting via TDHS (Time Domain Harmonic Scaling).

#### Pitch Shift
Shifts pitch without changing tempo.

- **Algorithm**: SoundTouch `setPitchSemiTones()`. Input is fed to SoundTouch, output retrieved in on_chunk(). Latency reported via `get_latency()`.
- **Parameters**:
  | Parameter | Range | Default | Unit |
  |-----------|-------|---------|------|
  | Pitch | -12.0 - 12.0 | 0.0 | semitones |
- **Metadata tag**: Reads `pitch_amt` tag for per-track override
- **Preset format**: `[pitch_semitones: float]`

#### Tempo Shift
Changes playback speed without changing pitch.

- **Algorithm**: SoundTouch `setTempoChange()`. Percentage-based speed adjustment.
- **Parameters**:
  | Parameter | Range | Default | Unit |
  |-----------|-------|---------|------|
  | Tempo | -50.0 - 100.0 | 0.0 | % change |
- **Metadata tag**: Reads `tempo_amt` tag for per-track override
- **Preset format**: `[tempo_pct: float]`

#### Rate Shift
Changes both speed and pitch proportionally (like changing vinyl RPM).

- **Algorithm**: SoundTouch `setRateChange()`. Simple resampling ratio adjustment.
- **Parameters**:
  | Parameter | Range | Default | Unit |
  |-----------|-------|---------|------|
  | Rate | -50.0 - 100.0 | 0.0 | % change |
- **Metadata tag**: Reads `pbrate_amt` tag for per-track override
- **Preset format**: `[rate_pct: float]`

---

## 3. Architecture

### 3.1 Directory Structure

```
foo_jl_effects_dsp_mac/
  src/
    Core/
      EffectBase.h/cpp          # dsp_impl_base wrapper with buffer management
      LFO.h/cpp                 # Shared oscillator for modulation effects
      BiquadFilter.h/cpp        # IIR biquad implementation (Audio EQ Cookbook)
      MetadataReader.h/cpp      # pitch_amt/tempo_amt/pbrate_amt tag reading
    Effects/
      Echo.h/cpp
      Tremolo.h/cpp
      IIRFilter.h/cpp
      Phaser.h/cpp
      WahWah.h/cpp
      Reverb.h/cpp
      Chorus.h/cpp
      Vibrato.h/cpp
      PitchShift.h/cpp
      TempoShift.h/cpp
      RateShift.h/cpp
    UI/
      EffectConfigBase.h/mm     # Base NSViewController for config popups
      ParameterSlider.h/mm      # Reusable slider+label+value row
      [11 effect config views]  # One per effect (XIB + .mm)
    ThirdParty/
      SoundTouch/               # MIT license, compiled in-tree
      Freeverb/                 # Public domain, ~200 lines
    Integration/
      Main.mm                   # Component registration, 11 factory instances
    fb2k_sdk.h
    Prefix.pch
  Resources/
    [XIB files for config UIs]
  Scripts/
    build.sh
    install.sh
    generate_xcode_project.rb
  docs/
    FOUNDATION.md               # This document
  build/                        # Build output (gitignored)
```

### 3.2 Design Decisions

**One DSP per effect, not one DSP with 11 modes.** foobar2000's DSP chain model expects each effect to be independently addable, removable, and reorderable. Each effect has its own GUID, factory, and preset format. This matches the original Windows component's behavior and the SDK's design intent.

**Shared `EffectBase` class.** All 11 effects share common boilerplate:
- Constructor parses preset, destructor is trivial
- `flush()` resets internal state (delay buffers, phase accumulators, SoundTouch instances)
- `get_latency()` returns 0 for most effects, non-zero for SoundTouch effects
- `need_track_change_mark()` returns true only for SoundTouch effects (for metadata tag reading)
- Buffer pre-allocation in constructor or `on_chunk()` first call (with size guard)
- Preset make/parse helpers

**Config popups use NSViewController + XIB.** Following the SDK sample pattern (`fooSampleDSPView.mm`):
- Each effect has a `FooEffectNameView` NSViewController subclass
- Parameters bound via KVO or direct IBAction
- Changes pushed to host via `dsp_preset_edit_callback_v2::ptr`
- View returned to host wrapped with `fb2k::wrapNSObject()`

**Reusable `ParameterSlider` component.** Most effects have 2-5 float parameters each rendered as a horizontal row: `[Label] [Slider] [Value Field]`. A shared `ParameterSlider` NSView avoids duplicating this layout 50+ times.

---

## 4. DSP Registration Pattern

Each effect follows this pattern, derived from the SDK sample:

### Header (e.g., `Echo.h`)

```cpp
#pragma once
#include "Core/EffectBase.h"

namespace effects_dsp {

namespace echo_common {
    static constexpr GUID guid = { /* unique GUID */ };

    static void make_preset(float delay_ms, float feedback, float wet_dry,
                           dsp_preset& out) {
        dsp_preset_builder builder;
        builder << delay_ms << feedback << wet_dry;
        builder.finish(guid, out);
    }

    struct Params {
        float delay_ms = 200.0f;
        float feedback = 0.5f;
        float wet_dry = 0.5f;
    };

    static Params parse_preset(const dsp_preset& in) {
        Params p;
        try {
            dsp_preset_parser parser(in);
            parser >> p.delay_ms >> p.feedback >> p.wet_dry;
        } catch (exception_io_data const&) {}
        return p;
    }
}

} // namespace effects_dsp
```

### Implementation (e.g., `Echo.cpp`)

```cpp
#include "Echo.h"

namespace effects_dsp {

class dsp_echo : public dsp_impl_base {
public:
    dsp_echo(dsp_preset const& in) : m_params(echo_common::parse_preset(in)) {
        // Pre-allocate delay buffer for max delay at max sample rate
    }

    static GUID g_get_guid() { return echo_common::guid; }
    static void g_get_name(pfc::string_base& out) { out = "Echo"; }

    bool on_chunk(audio_chunk* chunk, abort_callback&) override {
        // Process audio with echo effect
        return true;
    }

    void flush() override {
        // Clear delay buffer, reset write position
    }

    double get_latency() override { return 0; }
    bool need_track_change_mark() override { return false; }

    static bool g_get_default_preset(dsp_preset& out) {
        echo_common::make_preset(200.0f, 0.5f, 0.5f, out);
        return true;
    }

    static bool g_have_config_popup() { return true; }

#ifdef __APPLE__
    static service_ptr g_show_config_popup(fb2k::hwnd_t parent,
                                           dsp_preset_edit_callback_v2::ptr callback) {
        return ConfigureEchoDSP(parent, callback);
    }
#endif

private:
    echo_common::Params m_params;
    std::vector<float> m_delay_buffer;  // Pre-allocated
    size_t m_write_pos = 0;
};

static dsp_factory_t<dsp_echo> g_dsp_echo_factory;

} // namespace effects_dsp
```

### macOS Config View (e.g., `EchoConfigView.mm`)

```objc
@interface EchoConfigView : NSViewController
@property (nonatomic) dsp_preset_edit_callback_v2::ptr callback;
@property (nonatomic) NSNumber* delayMs;
@property (nonatomic) NSNumber* feedback;
@property (nonatomic) NSNumber* wetDry;
@end

@implementation EchoConfigView

- (instancetype)init {
    return [self initWithNibName:@"EchoConfigView"
                          bundle:[NSBundle bundleForClass:[self class]]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    dsp_preset_impl preset;
    _callback->get_preset(preset);
    auto params = effects_dsp::echo_common::parse_preset(preset);
    self.delayMs = @(params.delay_ms);
    self.feedback = @(params.feedback);
    self.wetDry = @(params.wet_dry);
}

- (IBAction)onParameterChanged:(id)sender {
    dsp_preset_impl preset;
    effects_dsp::echo_common::make_preset(
        self.delayMs.floatValue,
        self.feedback.floatValue,
        self.wetDry.floatValue,
        preset);
    _callback->set_preset(preset);
}

@end

service_ptr ConfigureEchoDSP(fb2k::hwnd_t parent,
                             dsp_preset_edit_callback_v2::ptr callback) {
    EchoConfigView* view = [EchoConfigView new];
    view.callback = callback;
    return fb2k::wrapNSObject(view);
}
```

---

## 5. Preset Serialization

All effects use `dsp_preset_builder` / `dsp_preset_parser` from the SDK. This provides:
- Automatic byte-order handling
- Exception-safe parsing with fallback to defaults
- Forward-compatible reading (extra fields at end are ignored)

Each effect's preset is identified by its unique GUID. The builder writes parameters sequentially; the parser reads them in the same order. Adding new parameters in future versions should append to the end to maintain backward compatibility.

---

## 6. Real-Time Safety

Per `knowledge_base/06_AUDIO_PROCESSING.md`, the `on_chunk()` method runs on the audio thread and must be real-time safe.

### Forbidden in on_chunk()

| Operation | Why |
|-----------|-----|
| `new` / `malloc` / `std::vector::push_back` | Memory allocation blocks |
| `std::mutex` / `@synchronized` | Potential priority inversion |
| `NSLog` / `console::info()` | Synchronized I/O |
| `[obj doSomething]` | ObjC dispatch + autorelease pool |
| File I/O | Unbounded latency |
| `pfc::string8` construction | Heap allocation |

### Required Patterns

- **Pre-allocate all buffers** in the constructor or on first `on_chunk()` call (guarded by a `m_initialized` flag with size check)
- **`std::atomic<float>`** for parameters updated from the UI thread
- **No ObjC in the audio path** -- config views communicate via preset callbacks, not direct method calls
- **Buffer size guard**: If `on_chunk()` receives a chunk larger than the pre-allocated buffer, resize once (this is the only acceptable allocation point, and it should only happen on format changes)

### Latency Reporting

- Simple effects (Echo, Tremolo, IIR Filter, etc.): `get_latency()` returns 0 (they process sample-by-sample or use internal delay buffers that don't add pipeline delay)
- SoundTouch effects (Pitch/Tempo/Rate Shift): `get_latency()` returns the actual latency from `SoundTouch::getSetting(SETTING_INITIAL_LATENCY)` converted to seconds

---

## 7. Dependencies

### SoundTouch (MIT License)

- **Version**: Latest stable (4.x)
- **Integration**: Source compiled in-tree. Copy `source/SoundTouch/` into `src/ThirdParty/SoundTouch/`
- **Files needed**: `AAFilter.cpp`, `FIFOSampleBuffer.cpp`, `FIRFilter.cpp`, `RateTransposer.cpp`, `SoundTouch.cpp`, `TDStretch.cpp`, `InterpolateLinear.cpp`, `InterpolateCubic.cpp`, `InterpolateShannon.cpp`, `cpu_detect_x86.cpp` + headers
- **Build**: Added to Xcode project via `generate_xcode_project.rb` as additional source files
- **Configuration**: Define `SOUNDTOUCH_INTEGER_SAMPLES=0` (use float processing). On Apple Silicon, ARM NEON optimizations are enabled automatically via `STTypes.h`

### Freeverb (Public Domain)

- **Source**: Jezar's Freeverb, public domain
- **Files**: `revmodel.cpp`, `revmodel.h`, `comb.h`, `allpass.h`, `tuning.h` (~200 lines total)
- **Integration**: Copy into `src/ThirdParty/Freeverb/`, compile as part of the project
- **Modifications**: None expected; the original C++ code compiles cleanly on modern compilers

### BiquadFilter (Custom)

- **Source**: Implemented from Robert Bristow-Johnson's "Audio EQ Cookbook" formulas
- **Location**: `src/Core/BiquadFilter.h/cpp`
- **Used by**: IIR Filter, Phaser, WahWah

### LFO (Custom)

- **Source**: Simple sine/triangle oscillator with phase accumulator
- **Location**: `src/Core/LFO.h/cpp`
- **Used by**: Chorus, Vibrato, Phaser, WahWah, Tremolo (Tremolo may use its own inline oscillator given its simplicity)

---

## 8. Phased Implementation Plan

### Phase 1: Infrastructure + Simple Effects

| Deliverable | Details |
|-------------|---------|
| Scaffold | Project structure, `generate_xcode_project.rb`, build scripts |
| `EffectBase` | Base class with preset helpers, buffer management |
| `BiquadFilter` | Full 12-type biquad implementation |
| `ParameterSlider` | Reusable UI component |
| `EffectConfigBase` | Base NSViewController for config views |
| Echo | Full implementation + config UI |
| Tremolo | Full implementation + config UI |
| IIR Filter | Full implementation + config UI (with filter type picker) |

**Exit criteria**: Three effects build, install, and process audio correctly. Config popups work. Presets save/restore.

### Phase 2: Filters, Reverb & Modulation

| Deliverable | Details |
|-------------|---------|
| Freeverb integration | Copy source, add to project |
| `LFO` | Shared oscillator class |
| Reverb | Full implementation + config UI |
| Phaser | Full implementation + config UI |
| WahWah | Full implementation + config UI |
| Chorus | Full implementation + config UI |
| Vibrato | Full implementation + config UI |

**Exit criteria**: Seven effects working. All filter-based and modulation effects verified.

### Phase 3: SoundTouch Effects

| Deliverable | Details |
|-------------|---------|
| SoundTouch integration | Copy source, add to project, verify ARM NEON |
| `MetadataReader` | Tag-based parameter override (`pitch_amt`, `tempo_amt`, `pbrate_amt`) |
| Pitch Shift | Full implementation + config UI + tag override |
| Tempo Shift | Full implementation + config UI + tag override |
| Rate Shift | Full implementation + config UI + tag override |
| Latency reporting | `get_latency()` from SoundTouch initial latency |

**Exit criteria**: All 11 effects working. SoundTouch effects report correct latency. Metadata tag overrides functional.

### Phase 4: Polish & Release

| Deliverable | Details |
|-------------|---------|
| A/B testing | Compare output with Windows `foo_dsp_effect` |
| Sample rate testing | Verify at 44.1, 48, 88.2, 96, 176.4, 192 kHz |
| Channel config testing | Mono, stereo, 5.1, 7.1 |
| Seek testing | Verify `flush()` clears state correctly |
| Conversion workflow | Verify DSP works in file converter |
| Performance profiling | Instruments Time Profiler, check CPU usage |
| Documentation | User-facing docs, changelog |
| Release | v1.0.0 via `release_component.sh` |

---

## 9. Testing Strategy

### Functional Testing

- **A/B comparison**: Run identical audio through both Windows `foo_dsp_effect` and this component with the same parameters. Output should be perceptually identical (exact bit-for-bit match is not required due to float precision differences across platforms).
- **Parameter sweep**: Test each parameter at min, max, default, and several intermediate values.
- **Preset persistence**: Save a preset, restart foobar2000, verify parameters are restored.
- **Chain ordering**: Verify effects work correctly when reordered in the DSP chain.

### Edge Cases

- **Sample rate changes**: Effects must reinitialize buffers when sample rate changes mid-stream (e.g., switching from 44.1 kHz to 96 kHz track).
- **Channel count changes**: Mono to stereo transitions, surround sound passthrough.
- **Empty chunks**: `on_chunk()` with 0 samples should be a no-op.
- **Seeking**: `flush()` must fully reset state -- no artifacts from previous audio leaking through.
- **Rapid preset changes**: Config popup changes should not cause glitches (atomic parameter updates).

### Performance

- **CPU budget**: Each individual effect should use < 5% CPU at 192 kHz stereo on Apple Silicon.
- **Stacked effects**: All 11 effects active simultaneously should remain under 30% CPU.
- **Memory**: Total memory footprint for all effects < 10 MB (dominated by SoundTouch and echo delay buffers).
- **Profiling**: Use Instruments Time Profiler to identify hotspots. Use Allocations instrument to verify no allocations in `on_chunk()`.
