#include "BiquadFilter.h"

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

namespace effects_dsp {

void BiquadFilter::recalculate() {
    double w0 = 2.0 * M_PI * m_freq / m_sample_rate;
    double cos_w0 = std::cos(w0);
    double sin_w0 = std::sin(w0);
    double alpha = sin_w0 / (2.0 * m_q);
    double A = std::pow(10.0, m_gain_db / 40.0); // for peaking/shelf

    auto& c = m_coeffs;

    switch (m_type) {
    case BiquadType::Lowpass:
        c.b0 = (1.0 - cos_w0) / 2.0;
        c.b1 = 1.0 - cos_w0;
        c.b2 = (1.0 - cos_w0) / 2.0;
        c.a0 = 1.0 + alpha;
        c.a1 = -2.0 * cos_w0;
        c.a2 = 1.0 - alpha;
        break;

    case BiquadType::Highpass:
        c.b0 = (1.0 + cos_w0) / 2.0;
        c.b1 = -(1.0 + cos_w0);
        c.b2 = (1.0 + cos_w0) / 2.0;
        c.a0 = 1.0 + alpha;
        c.a1 = -2.0 * cos_w0;
        c.a2 = 1.0 - alpha;
        break;

    case BiquadType::BandpassCSG:
        c.b0 = sin_w0 / 2.0;
        c.b1 = 0.0;
        c.b2 = -sin_w0 / 2.0;
        c.a0 = 1.0 + alpha;
        c.a1 = -2.0 * cos_w0;
        c.a2 = 1.0 - alpha;
        break;

    case BiquadType::BandpassCZPG:
        c.b0 = alpha;
        c.b1 = 0.0;
        c.b2 = -alpha;
        c.a0 = 1.0 + alpha;
        c.a1 = -2.0 * cos_w0;
        c.a2 = 1.0 - alpha;
        break;

    case BiquadType::Notch:
        c.b0 = 1.0;
        c.b1 = -2.0 * cos_w0;
        c.b2 = 1.0;
        c.a0 = 1.0 + alpha;
        c.a1 = -2.0 * cos_w0;
        c.a2 = 1.0 - alpha;
        break;

    case BiquadType::Allpass:
        c.b0 = 1.0 - alpha;
        c.b1 = -2.0 * cos_w0;
        c.b2 = 1.0 + alpha;
        c.a0 = 1.0 + alpha;
        c.a1 = -2.0 * cos_w0;
        c.a2 = 1.0 - alpha;
        break;

    case BiquadType::PeakingEQ:
        c.b0 = 1.0 + alpha * A;
        c.b1 = -2.0 * cos_w0;
        c.b2 = 1.0 - alpha * A;
        c.a0 = 1.0 + alpha / A;
        c.a1 = -2.0 * cos_w0;
        c.a2 = 1.0 - alpha / A;
        break;

    case BiquadType::LowShelf: {
        double sqrtA = std::sqrt(A);
        double two_sqrtA_alpha = 2.0 * sqrtA * alpha;
        c.b0 = A * ((A + 1.0) - (A - 1.0) * cos_w0 + two_sqrtA_alpha);
        c.b1 = 2.0 * A * ((A - 1.0) - (A + 1.0) * cos_w0);
        c.b2 = A * ((A + 1.0) - (A - 1.0) * cos_w0 - two_sqrtA_alpha);
        c.a0 = (A + 1.0) + (A - 1.0) * cos_w0 + two_sqrtA_alpha;
        c.a1 = -2.0 * ((A - 1.0) + (A + 1.0) * cos_w0);
        c.a2 = (A + 1.0) + (A - 1.0) * cos_w0 - two_sqrtA_alpha;
        break;
    }

    case BiquadType::HighShelf: {
        double sqrtA = std::sqrt(A);
        double two_sqrtA_alpha = 2.0 * sqrtA * alpha;
        c.b0 = A * ((A + 1.0) + (A - 1.0) * cos_w0 + two_sqrtA_alpha);
        c.b1 = -2.0 * A * ((A - 1.0) + (A + 1.0) * cos_w0);
        c.b2 = A * ((A + 1.0) + (A - 1.0) * cos_w0 - two_sqrtA_alpha);
        c.a0 = (A + 1.0) - (A - 1.0) * cos_w0 + two_sqrtA_alpha;
        c.a1 = 2.0 * ((A - 1.0) - (A + 1.0) * cos_w0);
        c.a2 = (A + 1.0) - (A - 1.0) * cos_w0 - two_sqrtA_alpha;
        break;
    }

    case BiquadType::Lowpass1stOrder:
        // 1st order lowpass: H(s) = 1 / (s + 1)
        // Using bilinear transform
        c.b0 = sin_w0 / (sin_w0 + cos_w0 + 1.0);
        c.b1 = c.b0;
        c.b2 = 0.0;
        c.a0 = 1.0;
        c.a1 = -(1.0 - cos_w0 - sin_w0) / (sin_w0 + cos_w0 + 1.0);
        c.a2 = 0.0;
        break;

    case BiquadType::Highpass1stOrder:
        // 1st order highpass: H(s) = s / (s + 1)
        c.b0 = (cos_w0 + 1.0) / (sin_w0 + cos_w0 + 1.0);
        c.b1 = -c.b0;
        c.b2 = 0.0;
        c.a0 = 1.0;
        c.a1 = -(1.0 - cos_w0 - sin_w0) / (sin_w0 + cos_w0 + 1.0);
        c.a2 = 0.0;
        break;

    case BiquadType::Allpass1stOrder:
        // 1st order allpass: H(s) = (s - 1) / (s + 1)
        c.b0 = (1.0 - cos_w0 - sin_w0) / (sin_w0 + cos_w0 + 1.0);
        c.b1 = 1.0;
        c.b2 = 0.0;
        c.a0 = 1.0;
        c.a1 = c.b0;
        c.a2 = 0.0;
        break;

    default:
        // Identity (passthrough)
        c.b0 = 1.0; c.b1 = 0.0; c.b2 = 0.0;
        c.a0 = 1.0; c.a1 = 0.0; c.a2 = 0.0;
        break;
    }
}

float BiquadFilter::process(float input, BiquadState& s) const {
    double x0 = static_cast<double>(input);
    double y0 = (m_coeffs.b0 * x0 + m_coeffs.b1 * s.x1 + m_coeffs.b2 * s.x2
                 - m_coeffs.a1 * s.y1 - m_coeffs.a2 * s.y2) / m_coeffs.a0;

    s.x2 = s.x1;
    s.x1 = x0;
    s.y2 = s.y1;
    s.y1 = y0;

    return static_cast<float>(y0);
}

void BiquadFilter::prepare_channels(size_t count) {
    if (m_states.size() != count) {
        m_states.resize(count);
        for (auto& s : m_states) s.reset();
    }
}

void BiquadFilter::flush() {
    for (auto& s : m_states) s.reset();
}

} // namespace effects_dsp
