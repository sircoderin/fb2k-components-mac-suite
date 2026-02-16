#include "IIRFilter.h"
#include "Core/BiquadFilter.h"

namespace effects_dsp {

class dsp_iir_filter : public dsp_impl_base {
public:
    dsp_iir_filter(dsp_preset const& in) : m_params(iir_filter_common::parse_preset(in)) {
        configure_filter();
    }

    static GUID g_get_guid() { return iir_filter_common::guid; }
    static void g_get_name(pfc::string_base& out) { out = "IIR Filter"; }

    bool on_chunk(audio_chunk* chunk, abort_callback&) override {
        const auto sample_rate = chunk->get_sample_rate();
        const auto channels = chunk->get_channel_count();
        const auto sample_count = chunk->get_sample_count();
        audio_sample* data = chunk->get_data();

        // Recalculate coefficients if sample rate changed
        if (sample_rate != m_sample_rate) {
            m_sample_rate = sample_rate;
            m_filter.set_sample_rate(static_cast<double>(sample_rate));
            m_filter.recalculate();
        }

        // Ensure we have per-channel state
        m_filter.prepare_channels(channels);

        // Process each sample, each channel
        for (size_t s = 0; s < sample_count; ++s) {
            for (unsigned ch = 0; ch < channels; ++ch) {
                size_t idx = s * channels + ch;
                data[idx] = m_filter.process(data[idx], m_filter.channel_state(ch));
            }
        }

        return true;
    }

    void on_endofplayback(abort_callback&) override {}
    void on_endoftrack(abort_callback&) override {}

    void flush() override {
        m_filter.flush();
    }

    double get_latency() override { return 0; }
    bool need_track_change_mark() override { return false; }

    static bool g_get_default_preset(dsp_preset& out) {
        iir_filter_common::make_preset(iir_filter_common::Params{}, out);
        return true;
    }

    static bool g_have_config_popup() { return true; }

#ifdef __APPLE__
    static service_ptr g_show_config_popup(fb2k::hwnd_t parent,
                                           dsp_preset_edit_callback_v2::ptr callback) {
        return ConfigureIIRFilterDSP(parent, callback);
    }
#endif

private:
    void configure_filter() {
        m_filter.set_type(static_cast<BiquadType>(m_params.filter_type));
        m_filter.set_frequency(m_params.freq);
        m_filter.set_q(m_params.q);
        m_filter.set_gain_db(m_params.gain_db);
        m_filter.set_sample_rate(static_cast<double>(m_sample_rate));
        m_filter.recalculate();
    }

    iir_filter_common::Params m_params;
    BiquadFilter m_filter;
    unsigned m_sample_rate = 44100;
};

static dsp_factory_t<dsp_iir_filter> g_dsp_iir_filter_factory;

} // namespace effects_dsp
