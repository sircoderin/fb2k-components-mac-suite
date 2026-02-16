#include "Vibrato.h"
#include "Core/LFO.h"
#include <vector>
#include <cmath>
#include <algorithm>

namespace effects_dsp {

// Max delay for vibrato: 20ms at 192kHz
static const size_t kMaxDelaySamples = 3840;
static const int kMaxChannels = 8;

class dsp_vibrato : public dsp_impl_base {
public:
    dsp_vibrato(dsp_preset const& in) : m_params(vibrato_common::parse_preset(in)) {
        m_lfo.set_waveform(LFOWaveform::Sine);
    }

    static GUID g_get_guid() { return vibrato_common::guid; }
    static void g_get_name(pfc::string_base& out) { out = "Vibrato"; }

    bool on_chunk(audio_chunk* chunk, abort_callback&) override {
        const auto sample_rate = chunk->get_sample_rate();
        const auto channels = chunk->get_channel_count();
        const auto sample_count = chunk->get_sample_count();
        audio_sample* data = chunk->get_data();

        if (sample_rate != m_sample_rate || channels != m_channels) {
            m_sample_rate = sample_rate;
            m_channels = channels;
            m_lfo.set_sample_rate(sample_rate);
            unsigned ch_count = std::min(channels, (unsigned)kMaxChannels);
            for (unsigned ch = 0; ch < ch_count; ++ch) {
                m_delay_buf[ch].assign(kMaxDelaySamples, 0.0f);
            }
            m_write_pos = 0;
        }
        m_lfo.set_frequency(m_params.rate);

        const unsigned ch_count = std::min(channels, (unsigned)kMaxChannels);
        // Base delay: half of max sweep range (~5ms)
        const float base_delay_samples = 5.0f * 0.001f * m_sample_rate;
        const float sweep_samples = base_delay_samples * m_params.depth;

        for (size_t s = 0; s < sample_count; ++s) {
            float lfo_val = m_lfo.tick();
            // Modulated delay
            float mod_delay = base_delay_samples + sweep_samples * lfo_val;
            mod_delay = std::max(1.0f, std::min(mod_delay, (float)(kMaxDelaySamples - 1)));

            int delay_int = static_cast<int>(mod_delay);
            float frac = mod_delay - delay_int;

            for (unsigned ch = 0; ch < ch_count; ++ch) {
                size_t idx = s * channels + ch;

                // Write input to delay buffer
                m_delay_buf[ch][m_write_pos] = data[idx];

                // Read with linear interpolation
                int read_pos1 = (int)m_write_pos - delay_int;
                if (read_pos1 < 0) read_pos1 += kMaxDelaySamples;
                int read_pos2 = read_pos1 - 1;
                if (read_pos2 < 0) read_pos2 += kMaxDelaySamples;

                data[idx] = m_delay_buf[ch][read_pos1] * (1.0f - frac)
                          + m_delay_buf[ch][read_pos2] * frac;
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
        vibrato_common::make_preset(vibrato_common::Params{}, out);
        return true;
    }

    static bool g_have_config_popup() { return true; }

#ifdef __APPLE__
    static service_ptr g_show_config_popup(fb2k::hwnd_t parent,
                                           dsp_preset_edit_callback_v2::ptr callback) {
        return ConfigureVibratoDSP(parent, callback);
    }
#endif

private:
    vibrato_common::Params m_params;
    LFO m_lfo;
    unsigned m_sample_rate = 0;
    unsigned m_channels = 0;
    std::vector<float> m_delay_buf[kMaxChannels];
    size_t m_write_pos = 0;
};

static dsp_factory_t<dsp_vibrato> g_dsp_vibrato_factory;

} // namespace effects_dsp
