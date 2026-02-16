#pragma once

#include <cmath>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

namespace effects_dsp {

enum class LFOWaveform {
    Sine,
    Triangle
};

// Low-frequency oscillator with phase accumulator.
// Thread-safe for single-writer (audio thread) use.
class LFO {
public:
    void set_frequency(double freq) { m_freq = freq; }
    void set_sample_rate(double sr) { m_sample_rate = sr; }
    void set_waveform(LFOWaveform w) { m_waveform = w; }

    // Get the current LFO value in [-1, 1] and advance phase
    float tick() {
        float out = 0.0f;
        switch (m_waveform) {
        case LFOWaveform::Sine:
            out = static_cast<float>(std::sin(2.0 * M_PI * m_phase));
            break;
        case LFOWaveform::Triangle:
            // Triangle: rises from -1 to 1 over [0, 0.5], falls from 1 to -1 over [0.5, 1]
            if (m_phase < 0.5)
                out = static_cast<float>(4.0 * m_phase - 1.0);
            else
                out = static_cast<float>(3.0 - 4.0 * m_phase);
            break;
        }

        m_phase += m_freq / m_sample_rate;
        if (m_phase >= 1.0) m_phase -= 1.0;

        return out;
    }

    // Get current value without advancing
    float value() const {
        switch (m_waveform) {
        case LFOWaveform::Sine:
            return static_cast<float>(std::sin(2.0 * M_PI * m_phase));
        case LFOWaveform::Triangle:
            if (m_phase < 0.5)
                return static_cast<float>(4.0 * m_phase - 1.0);
            else
                return static_cast<float>(3.0 - 4.0 * m_phase);
        }
        return 0.0f;
    }

    double phase() const { return m_phase; }
    void set_phase(double p) { m_phase = p; }

    void reset() { m_phase = 0.0; }

private:
    LFOWaveform m_waveform = LFOWaveform::Sine;
    double m_freq = 1.0;
    double m_sample_rate = 44100.0;
    double m_phase = 0.0;
};

} // namespace effects_dsp
