#include "WahWah.h"
#include "Core/BiquadFilter.h"
#include "Core/LFO.h"

namespace effects_dsp {

class dsp_wahwah : public dsp_impl_base {
public:
    dsp_wahwah(dsp_preset const& in) : m_params(wahwah_common::parse_preset(in)) {
        m_lfo.set_waveform(LFOWaveform::Triangle);
        m_filter.set_type(BiquadType::BandpassCZPG);
    }

    static GUID g_get_guid() { return wahwah_common::guid; }
    static void g_get_name(pfc::string_base& out) { out = "WahWah"; }

    bool on_chunk(audio_chunk* chunk, abort_callback&) override {
        const auto sample_rate = chunk->get_sample_rate();
        const auto channels = chunk->get_channel_count();
        const auto sample_count = chunk->get_sample_count();
        audio_sample* data = chunk->get_data();

        if (sample_rate != m_sample_rate) {
            m_sample_rate = sample_rate;
            m_lfo.set_sample_rate(sample_rate);
            m_filter.set_sample_rate(sample_rate);
        }
        m_lfo.set_frequency(m_params.rate);
        m_filter.set_q(m_params.resonance);
        m_filter.prepare_channels(channels);

        for (size_t s = 0; s < sample_count; ++s) {
            float lfo_val = m_lfo.tick();
            // Sweep frequency: center +/- (range * depth * lfo)
            float sweep_freq = m_params.center_freq + m_params.freq_range * m_params.depth * lfo_val;
            sweep_freq = std::max(20.0f, std::min(sweep_freq, 20000.0f));
            m_filter.set_frequency(sweep_freq);
            m_filter.recalculate();

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
        m_lfo.reset();
        m_filter.flush();
    }

    double get_latency() override { return 0; }
    bool need_track_change_mark() override { return false; }

    static bool g_get_default_preset(dsp_preset& out) {
        wahwah_common::make_preset(wahwah_common::Params{}, out);
        return true;
    }

    static bool g_have_config_popup() { return true; }

#ifdef __APPLE__
    static service_ptr g_show_config_popup(fb2k::hwnd_t parent,
                                           dsp_preset_edit_callback_v2::ptr callback) {
        return ConfigureWahWahDSP(parent, callback);
    }
#endif

private:
    wahwah_common::Params m_params;
    LFO m_lfo;
    BiquadFilter m_filter;
    unsigned m_sample_rate = 0;
};

static dsp_factory_t<dsp_wahwah> g_dsp_wahwah_factory;

} // namespace effects_dsp
