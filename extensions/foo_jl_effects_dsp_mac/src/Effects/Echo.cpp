#include "Echo.h"
#include <vector>
#include <cstring>

namespace effects_dsp {

class dsp_echo : public dsp_impl_base {
public:
    dsp_echo(dsp_preset const& in) : m_params(echo_common::parse_preset(in)) {}

    static GUID g_get_guid() { return echo_common::guid; }
    static void g_get_name(pfc::string_base& out) { out = "Echo"; }

    bool on_chunk(audio_chunk* chunk, abort_callback&) override {
        const auto sample_rate = chunk->get_sample_rate();
        const auto channels = chunk->get_channel_count();
        const auto sample_count = chunk->get_sample_count();
        audio_sample* data = chunk->get_data();

        // Reinitialize if format changed
        if (sample_rate != m_sample_rate || channels != m_channels) {
            m_sample_rate = sample_rate;
            m_channels = channels;
            // Max delay buffer: 5 seconds at current sample rate, all channels
            m_buffer_size = static_cast<size_t>(5.0 * sample_rate) * channels;
            m_buffer.assign(m_buffer_size, 0.0f);
            m_write_pos = 0;
        }

        const size_t delay_samples = static_cast<size_t>(
            (m_params.delay_ms / 1000.0f) * sample_rate) * channels;

        if (delay_samples == 0 || delay_samples > m_buffer_size)
            return true;

        const float feedback = m_params.feedback;
        const float wet = m_params.wet_dry;
        const float dry = 1.0f - wet;

        for (size_t i = 0; i < sample_count * channels; ++i) {
            // Read delayed sample
            size_t read_pos = (m_write_pos + m_buffer_size - delay_samples) % m_buffer_size;
            float delayed = m_buffer[read_pos];

            // Write current input + feedback into buffer
            m_buffer[m_write_pos] = data[i] + delayed * feedback;

            // Output: dry * input + wet * delayed
            data[i] = dry * data[i] + wet * delayed;

            m_write_pos = (m_write_pos + 1) % m_buffer_size;
        }

        return true;
    }

    void on_endofplayback(abort_callback&) override {}
    void on_endoftrack(abort_callback&) override {}

    void flush() override {
        if (!m_buffer.empty()) {
            std::memset(m_buffer.data(), 0, m_buffer.size() * sizeof(float));
        }
        m_write_pos = 0;
    }

    double get_latency() override { return 0; }
    bool need_track_change_mark() override { return false; }

    static bool g_get_default_preset(dsp_preset& out) {
        echo_common::make_preset(echo_common::Params{}, out);
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
    std::vector<audio_sample> m_buffer;
    size_t m_buffer_size = 0;
    size_t m_write_pos = 0;
    unsigned m_sample_rate = 0;
    unsigned m_channels = 0;
};

static dsp_factory_t<dsp_echo> g_dsp_echo_factory;

} // namespace effects_dsp
