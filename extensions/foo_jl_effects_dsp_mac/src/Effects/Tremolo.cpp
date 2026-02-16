#include "Tremolo.h"
#include <cmath>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

namespace effects_dsp {

class dsp_tremolo : public dsp_impl_base {
public:
    dsp_tremolo(dsp_preset const& in) : m_params(tremolo_common::parse_preset(in)) {}

    static GUID g_get_guid() { return tremolo_common::guid; }
    static void g_get_name(pfc::string_base& out) { out = "Tremolo"; }

    bool on_chunk(audio_chunk* chunk, abort_callback&) override {
        const auto sample_rate = chunk->get_sample_rate();
        const auto channels = chunk->get_channel_count();
        const auto sample_count = chunk->get_sample_count();
        audio_sample* data = chunk->get_data();

        const double phase_inc = m_params.freq / static_cast<double>(sample_rate);
        const float depth = m_params.depth;

        for (size_t s = 0; s < sample_count; ++s) {
            // LFO: modulation factor = 1 - depth * sin(2*pi*phase)
            float mod = 1.0f - depth * static_cast<float>(std::sin(2.0 * M_PI * m_phase));

            // Apply to all channels for this sample
            for (unsigned ch = 0; ch < channels; ++ch) {
                data[s * channels + ch] *= mod;
            }

            m_phase += phase_inc;
            if (m_phase >= 1.0) m_phase -= 1.0;
        }

        return true;
    }

    void on_endofplayback(abort_callback&) override {}
    void on_endoftrack(abort_callback&) override {}

    void flush() override {
        m_phase = 0.0;
    }

    double get_latency() override { return 0; }
    bool need_track_change_mark() override { return false; }

    static bool g_get_default_preset(dsp_preset& out) {
        tremolo_common::make_preset(tremolo_common::Params{}, out);
        return true;
    }

    static bool g_have_config_popup() { return true; }

#ifdef __APPLE__
    static service_ptr g_show_config_popup(fb2k::hwnd_t parent,
                                           dsp_preset_edit_callback_v2::ptr callback) {
        return ConfigureTremoloDSP(parent, callback);
    }
#endif

private:
    tremolo_common::Params m_params;
    double m_phase = 0.0;
};

static dsp_factory_t<dsp_tremolo> g_dsp_tremolo_factory;

} // namespace effects_dsp
