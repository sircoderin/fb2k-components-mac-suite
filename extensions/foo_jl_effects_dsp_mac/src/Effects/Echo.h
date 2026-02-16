#pragma once
#include <foobar2000/SDK/dsp.h>

#ifdef __APPLE__
service_ptr ConfigureEchoDSP(fb2k::hwnd_t parent, dsp_preset_edit_callback_v2::ptr callback);
#endif

namespace effects_dsp {

namespace echo_common {
    // {93A68A15-0A09-47A2-9C5C-EDA13BC4E0A0}
    static constexpr GUID guid = { 0x93a68a15, 0x0a09, 0x47a2,
        { 0x9c, 0x5c, 0xed, 0xa1, 0x3b, 0xc4, 0xe0, 0xa0 } };

    struct Params {
        float delay_ms = 200.0f;
        float feedback = 0.5f;
        float wet_dry = 0.5f;
    };

    static void make_preset(const Params& p, dsp_preset& out) {
        dsp_preset_builder builder;
        builder << p.delay_ms << p.feedback << p.wet_dry;
        builder.finish(guid, out);
    }

    static Params parse_preset(const dsp_preset& in) {
        Params p;
        try {
            dsp_preset_parser parser(in);
            parser >> p.delay_ms >> p.feedback >> p.wet_dry;
        } catch (exception_io_data const&) {}
        return p;
    }
}

} // namespace effects_dsp
