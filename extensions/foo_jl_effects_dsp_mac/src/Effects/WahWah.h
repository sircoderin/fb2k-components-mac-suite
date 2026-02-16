#pragma once
#include <foobar2000/SDK/dsp.h>

#ifdef __APPLE__
service_ptr ConfigureWahWahDSP(fb2k::hwnd_t parent, dsp_preset_edit_callback_v2::ptr callback);
#endif

namespace effects_dsp {

namespace wahwah_common {
    // {62815E4B-BB3E-4E13-9B0C-B00B86892A74}
    static constexpr GUID guid = { 0x62815e4b, 0xbb3e, 0x4e13,
        { 0x9b, 0x0c, 0xb0, 0x0b, 0x86, 0x89, 0x2a, 0x74 } };

    struct Params {
        float rate = 1.5f;
        float depth = 0.7f;
        float resonance = 2.5f;
        float center_freq = 700.0f;
        float freq_range = 500.0f;
    };

    static void make_preset(const Params& p, dsp_preset& out) {
        dsp_preset_builder builder;
        builder << p.rate << p.depth << p.resonance << p.center_freq << p.freq_range;
        builder.finish(guid, out);
    }

    static Params parse_preset(const dsp_preset& in) {
        Params p;
        try {
            dsp_preset_parser parser(in);
            parser >> p.rate >> p.depth >> p.resonance >> p.center_freq >> p.freq_range;
        } catch (exception_io_data const&) {}
        return p;
    }
}

} // namespace effects_dsp
