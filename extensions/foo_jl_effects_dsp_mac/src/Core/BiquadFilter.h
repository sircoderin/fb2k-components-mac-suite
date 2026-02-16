#pragma once

#include <cmath>
#include <vector>

namespace effects_dsp {

enum class BiquadType : int {
    Lowpass = 0,
    Highpass,
    BandpassCSG,   // constant skirt gain
    BandpassCZPG,  // constant 0 dB peak gain
    Notch,
    Allpass,
    PeakingEQ,
    LowShelf,
    HighShelf,
    Lowpass1stOrder,
    Highpass1stOrder,
    Allpass1stOrder,
    Count
};

static const char* biquad_type_names[] = {
    "Lowpass",
    "Highpass",
    "Bandpass (CSG)",
    "Bandpass (CZPG)",
    "Notch",
    "All-pass",
    "Peaking EQ",
    "Low Shelf",
    "High Shelf",
    "Lowpass (1st order)",
    "Highpass (1st order)",
    "All-pass (1st order)"
};

// Returns true if the given filter type uses the gain parameter
inline bool biquad_type_uses_gain(BiquadType type) {
    return type == BiquadType::PeakingEQ ||
           type == BiquadType::LowShelf ||
           type == BiquadType::HighShelf;
}

// Per-channel biquad filter state
struct BiquadState {
    double x1 = 0, x2 = 0; // input history
    double y1 = 0, y2 = 0; // output history

    void reset() { x1 = x2 = y1 = y2 = 0; }
};

// Biquad filter coefficients (shared across channels)
struct BiquadCoeffs {
    double b0 = 1, b1 = 0, b2 = 0;
    double a0 = 1, a1 = 0, a2 = 0;
};

class BiquadFilter {
public:
    void set_type(BiquadType type) { m_type = type; }
    void set_frequency(double freq) { m_freq = freq; }
    void set_q(double q) { m_q = q; }
    void set_gain_db(double gain) { m_gain_db = gain; }
    void set_sample_rate(double sr) { m_sample_rate = sr; }

    // Recalculate coefficients from current parameters.
    // Call after changing type/freq/q/gain/sample_rate.
    void recalculate();

    // Process a single sample for a given channel
    float process(float input, BiquadState& state) const;

    // Reset all channel states
    void prepare_channels(size_t count);
    BiquadState& channel_state(size_t ch) { return m_states[ch]; }

    void flush();

private:
    BiquadType m_type = BiquadType::Lowpass;
    double m_freq = 1000.0;
    double m_q = 0.707;
    double m_gain_db = 0.0;
    double m_sample_rate = 44100.0;

    BiquadCoeffs m_coeffs;
    std::vector<BiquadState> m_states;
};

} // namespace effects_dsp
