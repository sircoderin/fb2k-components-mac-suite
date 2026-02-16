#include "Phaser.h"
#include "Core/LFO.h"
#include <vector>
#include <cmath>
#include <cstring>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

namespace effects_dsp {

static const int kMaxStages = 12;
static const int kMaxChannels = 8;

class dsp_phaser : public dsp_impl_base {
public:
    dsp_phaser(dsp_preset const& in) : m_params(phaser_common::parse_preset(in)) {}

    static GUID g_get_guid() { return phaser_common::guid; }
    static void g_get_name(pfc::string_base& out) { out = "Phaser"; }

    bool on_chunk(audio_chunk* chunk, abort_callback&) override {
        const auto sample_rate = chunk->get_sample_rate();
        const auto channels = chunk->get_channel_count();
        const auto sample_count = chunk->get_sample_count();
        audio_sample* data = chunk->get_data();

        if (sample_rate != m_sample_rate) {
            m_sample_rate = sample_rate;
            m_lfo.set_sample_rate(sample_rate);
        }
        m_lfo.set_frequency(m_params.rate);

        const int stages = std::min(m_params.stages, (int32_t)kMaxStages);
        const unsigned ch_count = std::min(channels, (unsigned)kMaxChannels);
        const float depth = m_params.depth;
        const float feedback = m_params.feedback;
        const float wet = m_params.wet_dry;
        const float dry = 1.0f - wet;

        // Min/max frequency for allpass sweep (Hz)
        const double fMin = 100.0;
        const double fMax = 4000.0;

        for (size_t s = 0; s < sample_count; ++s) {
            float lfo_val = m_lfo.tick();
            // Map LFO [-1,1] to frequency range
            double sweep_freq = fMin + (fMax - fMin) * 0.5 * (1.0 + lfo_val * depth);
            // Convert to allpass coefficient
            double w = 2.0 * M_PI * sweep_freq / m_sample_rate;
            float coeff = static_cast<float>((1.0 - std::tan(w * 0.5)) / (1.0 + std::tan(w * 0.5)));

            for (unsigned ch = 0; ch < ch_count; ++ch) {
                size_t idx = s * channels + ch;
                float input = data[idx] + m_feedback_buf[ch] * feedback;
                float allpass_out = input;

                // Chain of allpass filters
                for (int st = 0; st < stages; ++st) {
                    float tmp = coeff * (allpass_out - m_state[ch][st]);
                    allpass_out = m_state[ch][st] + tmp + coeff * allpass_out;
                    // Simplified 1st-order allpass: y = coeff * (x - y_prev) + x_prev
                    float new_out = coeff * allpass_out + m_state[ch][st];
                    m_state[ch][st] = allpass_out;
                    allpass_out = new_out;
                }

                m_feedback_buf[ch] = allpass_out;
                data[idx] = dry * data[idx] + wet * allpass_out;
            }
        }

        return true;
    }

    void on_endofplayback(abort_callback&) override {}
    void on_endoftrack(abort_callback&) override {}

    void flush() override {
        m_lfo.reset();
        std::memset(m_state, 0, sizeof(m_state));
        std::memset(m_feedback_buf, 0, sizeof(m_feedback_buf));
    }

    double get_latency() override { return 0; }
    bool need_track_change_mark() override { return false; }

    static bool g_get_default_preset(dsp_preset& out) {
        phaser_common::make_preset(phaser_common::Params{}, out);
        return true;
    }

    static bool g_have_config_popup() { return true; }

#ifdef __APPLE__
    static service_ptr g_show_config_popup(fb2k::hwnd_t parent,
                                           dsp_preset_edit_callback_v2::ptr callback) {
        return ConfigurePhaserDSP(parent, callback);
    }
#endif

private:
    phaser_common::Params m_params;
    LFO m_lfo;
    unsigned m_sample_rate = 0;
    float m_state[kMaxChannels][kMaxStages] = {};
    float m_feedback_buf[kMaxChannels] = {};
};

static dsp_factory_t<dsp_phaser> g_dsp_phaser_factory;

} // namespace effects_dsp
