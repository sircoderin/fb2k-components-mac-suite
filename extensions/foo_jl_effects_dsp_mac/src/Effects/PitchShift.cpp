#include "PitchShift.h"
#include "Core/MetadataReader.h"
#include "ThirdParty/SoundTouch/SoundTouch.h"
#include <vector>
#include <cstring>

namespace effects_dsp {

class dsp_pitchshift : public dsp_impl_base {
public:
    dsp_pitchshift(dsp_preset const& in) : m_params(pitchshift_common::parse_preset(in)) {}

    static GUID g_get_guid() { return pitchshift_common::guid; }
    static void g_get_name(pfc::string_base& out) { out = "Pitch Shift"; }

    bool on_chunk(audio_chunk* chunk, abort_callback&) override {
        const auto sample_rate = chunk->get_sample_rate();
        const auto channels = chunk->get_channel_count();
        const auto sample_count = chunk->get_sample_count();
        audio_sample* data = chunk->get_data();

        if (sample_rate != m_sample_rate || channels != m_channels) {
            m_sample_rate = sample_rate;
            m_channels = channels;
            m_st.setSampleRate(sample_rate);
            m_st.setChannels(channels);
        }

        // Check for per-track metadata override
        float pitch = m_params.pitch_semitones;
        float tag_val = MetadataReader::read_float("pitch_amt", pitch);
        if (tag_val != pitch) pitch = tag_val;

        if (pitch == 0.0f) return true; // No processing needed

        m_st.setPitchSemiTones(static_cast<double>(pitch));

        // Convert audio_sample (double) to float for SoundTouch
        size_t total_samples = sample_count * channels;
        m_input_buf.resize(total_samples);
        for (size_t i = 0; i < total_samples; ++i) {
            m_input_buf[i] = static_cast<float>(data[i]);
        }

        m_st.putSamples(m_input_buf.data(), sample_count);

        // Retrieve processed samples
        m_output_buf.resize(total_samples * 2); // over-allocate for safety
        size_t total_received = 0;
        unsigned int received;
        do {
            received = m_st.receiveSamples(
                m_output_buf.data() + total_received * channels,
                static_cast<unsigned int>(m_output_buf.size() / channels - total_received));
            total_received += received;
        } while (received > 0);

        if (total_received > 0) {
            chunk->set_data_size(total_received * channels);
            audio_sample* out_data = chunk->get_data();
            for (size_t i = 0; i < total_received * channels; ++i) {
                out_data[i] = static_cast<audio_sample>(m_output_buf[i]);
            }
            chunk->set_sample_count(total_received);
        } else {
            return false; // No output yet (buffering)
        }

        return true;
    }

    void on_endofplayback(abort_callback&) override {
        m_st.flush();
    }

    void on_endoftrack(abort_callback&) override {}

    void flush() override {
        m_st.clear();
    }

    double get_latency() override {
        if (m_sample_rate == 0) return 0;
        int latency_samples = m_st.getSetting(SETTING_INITIAL_LATENCY);
        return static_cast<double>(latency_samples) / m_sample_rate;
    }

    bool need_track_change_mark() override { return true; }

    static bool g_get_default_preset(dsp_preset& out) {
        pitchshift_common::make_preset(pitchshift_common::Params{}, out);
        return true;
    }

    static bool g_have_config_popup() { return true; }

#ifdef __APPLE__
    static service_ptr g_show_config_popup(fb2k::hwnd_t parent,
                                           dsp_preset_edit_callback_v2::ptr callback) {
        return ConfigurePitchShiftDSP(parent, callback);
    }
#endif

private:
    pitchshift_common::Params m_params;
    soundtouch::SoundTouch m_st;
    unsigned m_sample_rate = 0;
    unsigned m_channels = 0;
    std::vector<float> m_input_buf;
    std::vector<float> m_output_buf;
};

static dsp_factory_t<dsp_pitchshift> g_dsp_pitchshift_factory;

} // namespace effects_dsp
