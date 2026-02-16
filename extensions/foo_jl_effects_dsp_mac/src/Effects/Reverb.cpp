#include "Reverb.h"
#include "ThirdParty/Freeverb/revmodel.h"
#include <vector>

namespace effects_dsp {

class dsp_reverb : public dsp_impl_base {
public:
    dsp_reverb(dsp_preset const& in) : m_params(reverb_common::parse_preset(in)) {
        apply_params();
    }

    static GUID g_get_guid() { return reverb_common::guid; }
    static void g_get_name(pfc::string_base& out) { out = "Reverb"; }

    bool on_chunk(audio_chunk* chunk, abort_callback&) override {
        const auto channels = chunk->get_channel_count();
        const auto sample_count = chunk->get_sample_count();
        audio_sample* data = chunk->get_data();

        if (channels == 1) {
            // Mono: duplicate to stereo float buffer, process, mix back
            m_tempL.resize(sample_count);
            m_tempR.resize(sample_count);
            for (size_t i = 0; i < sample_count; ++i) {
                m_tempL[i] = static_cast<float>(data[i]);
                m_tempR[i] = static_cast<float>(data[i]);
            }
            m_reverb.processreplace(m_tempL.data(), m_tempR.data(),
                                     m_tempL.data(), m_tempR.data(),
                                     static_cast<long>(sample_count), 1);
            for (size_t i = 0; i < sample_count; ++i) {
                data[i] = static_cast<audio_sample>((m_tempL[i] + m_tempR[i]) * 0.5f);
            }
        } else {
            // Stereo or multi-channel: convert to float, process L/R, convert back
            size_t total_samples = sample_count * channels;
            m_float_buf.resize(total_samples);
            for (size_t i = 0; i < total_samples; ++i) {
                m_float_buf[i] = static_cast<float>(data[i]);
            }
            m_reverb.processreplace(m_float_buf.data(), m_float_buf.data() + 1,
                                     m_float_buf.data(), m_float_buf.data() + 1,
                                     static_cast<long>(sample_count),
                                     static_cast<int>(channels));
            for (size_t i = 0; i < total_samples; ++i) {
                data[i] = static_cast<audio_sample>(m_float_buf[i]);
            }
        }

        return true;
    }

    void on_endofplayback(abort_callback&) override {}
    void on_endoftrack(abort_callback&) override {}

    void flush() override {
        m_reverb.mute();
    }

    double get_latency() override { return 0; }
    bool need_track_change_mark() override { return false; }

    static bool g_get_default_preset(dsp_preset& out) {
        reverb_common::make_preset(reverb_common::Params{}, out);
        return true;
    }

    static bool g_have_config_popup() { return true; }

#ifdef __APPLE__
    static service_ptr g_show_config_popup(fb2k::hwnd_t parent,
                                           dsp_preset_edit_callback_v2::ptr callback) {
        return ConfigureReverbDSP(parent, callback);
    }
#endif

private:
    void apply_params() {
        m_reverb.setroomsize(m_params.room_size);
        m_reverb.setdamp(m_params.damping);
        m_reverb.setwet(m_params.wet);
        m_reverb.setdry(m_params.dry);
        m_reverb.setwidth(m_params.width);
    }

    reverb_common::Params m_params;
    revmodel m_reverb;
    std::vector<float> m_tempL, m_tempR;
    std::vector<float> m_float_buf;
};

static dsp_factory_t<dsp_reverb> g_dsp_reverb_factory;

} // namespace effects_dsp
