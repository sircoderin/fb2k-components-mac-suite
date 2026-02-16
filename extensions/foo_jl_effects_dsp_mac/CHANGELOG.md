# Changelog

All notable changes to Effects DSP will be documented in this file.

## [1.0.0] - 2026-02-14

### Initial Release

macOS port of [foo_dsp_effect](https://github.com/mudlord/foo_dsp_effect) by mudlord. All 11 audio effects from the original Windows component, rebuilt for foobar2000 v2 macOS.

### Added

- **Echo**: Delay-based effect with configurable delay (1-5000ms), feedback, and wet/dry mix. Pre-allocated circular buffer for real-time safety.
- **Tremolo**: Amplitude modulation via sine LFO with adjustable rate (0.1-20 Hz) and depth.
- **IIR Filter**: 12-type biquad filter (lowpass, highpass, bandpass, notch, allpass, peaking EQ, shelves, and first-order variants). Coefficients from Robert Bristow-Johnson's Audio EQ Cookbook.
- **Reverb**: Room simulation using Jezar's Freeverb algorithm (8 parallel comb filters + 4 series allpass filters). Parameters: room size, damping, wet/dry levels, stereo width.
- **Phaser**: Multi-stage allpass filter sweep (2-12 stages) with LFO-controlled coefficient, feedback, and wet/dry mix.
- **WahWah**: Auto-wah using BiquadFilter bandpass with triangle LFO sweeping the center frequency. Configurable resonance, center frequency, and sweep range.
- **Chorus**: LFO-modulated delay line with linear interpolation, feedback, and wet/dry mix. Creates thickening/doubling effect.
- **Vibrato**: Pitch modulation via LFO-controlled variable delay with linear interpolation. Adjustable rate and depth.
- **Pitch Shift**: SoundTouch-based pitch shifting without tempo change (-12 to +12 semitones). Supports `pitch_amt` metadata tag override.
- **Tempo Shift**: SoundTouch-based tempo change without pitch change (-50% to +100%). Supports `tempo_amt` metadata tag override.
- **Rate Shift**: SoundTouch-based combined speed and pitch change (-50% to +100%). Supports `pbrate_amt` metadata tag override.
- **Programmatic config UIs**: All 11 effects have native macOS configuration popups built with NSStackView and reusable ParameterSlider components (no XIB files).
- **Real-time safe processing**: All `on_chunk()` implementations avoid allocations, ObjC dispatch, locks, and I/O on the audio thread.
- **Universal binary**: Builds for both Apple Silicon (arm64) and Intel (x86_64).
