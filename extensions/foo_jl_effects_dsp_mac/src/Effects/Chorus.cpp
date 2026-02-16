#include "Chorus.h"
#include "Core/LFO.h"
#include <vector>
#include <cmath>
#include <algorithm>

namespace effects_dsp {

// Max delay: 50ms at 192kHz
static const size_t kMaxDelaySamples = 9600;
static const int kMaxChannels = 8;

class dsp_chorus : public dsp_impl_base {
public:
    dsp_chorus(dsp_preset const& in) : m_params(chorus_common::parse_preset(in)) {
        m_lfo.set_waveform(LFOWaveform::Sine);
    }

    static GUID g_get_guid() { return chorus_common::guid; }
    static void g_get_name(pfc::string_base& out) { out = "Chorus"; }

    bool on_chunk(audio_chunk* chunk, abort_callback&) override {
        const auto sample_rate = chunk->get_sample_rate();
        const auto channels = chunk->get_channel_count();
        const auto sample_count = chunk->get_sample_count();
        audio_sample* data = chunk->get_data();

        if (sample_rate != m_sample_rate || channels != m_channels) {
            m_sample_rate = sample_rate;
            m_channels = channels;
            m_lfo.set_sample_rate(sample_rate);
            // Resize and clear delay buffer
            unsigned ch_count = std::min(channels, (unsigned)kMaxChannels);
            for (unsigned ch = 0; ch < ch_count; ++ch) {
                m_delay_buf[ch].assign(kMaxDelaySamples, 0.0f);
            }
            m_write_pos = 0;
        }
        m_lfo.set_frequency(m_params.rate);

        const unsigned ch_count = std::min(channels, (unsigned)kMaxChannels);
        const float base_delay_samples = m_params.delay_ms * 0.001f * m_sample_rate;
        const float depth = m_params.depth;
        const float feedback = m_params.feedback;
        const float wet = m_params.wet_dry;
        const float dry = 1.0f - wet;

        for (size_t s = 0; s < sample_count; ++s) {
            float lfo_val = m_lfo.tick();
            // Modulated delay in samples
            float mod_delay = base_delay_samples * (1.0f + depth * lfo_val);
            mod_delay = std::max(1.0f, std::min(mod_delay, (float)(kMaxDelaySamples - 1)));

            // Fractional delay for linear interpolation
            int delay_int = static_cast<int>(mod_delay);
            float frac = mod_delay - delay_int;

            for (unsigned ch = 0; ch < ch_count; ++ch) {
                size_t idx = s * channels + ch;
                float input = data[idx];

                // Read from delay buffer with linear interpolation
                int read_pos1 = (int)m_write_pos - delay_int;
                if (read_pos1 < 0) read_pos1 += kMaxDelaySamples;
                int read_pos2 = read_pos1 - 1;
                if (read_pos2 < 0) read_pos2 += kMaxDelaySamples;

                float delayed = m_delay_buf[ch][read_pos1] * (1.0f - frac)
                              + m_delay_buf[ch][read_pos2] * frac;

                // Write to delay buffer with feedback
                m_delay_buf[ch][m_write_pos] = input + delayed * feedback;

                // Mix
                data[idx] = dry * input + wet * delayed;
            }

            m_write_pos = (m_write_pos + 1) % kMaxDelaySamples;
        }

        return true;
    }

    void on_endofplayback(abort_callback&) override {}
    void on_endoftrack(abort_callback&) override {}

    void flush() override {
        m_lfo.reset();
        for (int ch = 0; ch < kMaxChannels; ++ch) {
            std::fill(m_delay_buf[ch].begin(), m_delay_buf[ch].end(), 0.0f);
        }
        m_write_pos = 0;
    }

    double get_latency() override { return 0; }
    bool need_track_change_mark() override { return false; }

    static bool g_get_default_preset(dsp_preset& out) {
        chorus_common::make_preset(chorus_common::Params{}, out);
        return true;
    }

    static bool g_have_config_popup() { return true; }

#ifdef __APPLE__
    static service_ptr g_show_config_popup(fb2k::hwnd_t parent,
                                           dsp_preset_edit_callback_v2::ptr callback) {
        return ConfigureChorusDSP(parent, callback);
    }
#endif

private:
    chorus_common::Params m_params;
    LFO m_lfo;
    unsigned m_sample_rate = 0;
    unsigned m_channels = 0;
    std::vector<float> m_delay_buf[kMaxChannels];
    size_t m_write_pos = 0;
};

static dsp_factory_t<dsp_chorus> g_dsp_chorus_factory;

} // namespace effects_dsp
