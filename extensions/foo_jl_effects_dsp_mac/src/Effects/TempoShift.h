#pragma once
#include <foobar2000/SDK/dsp.h>

#ifdef __APPLE__
service_ptr ConfigureTempoShiftDSP(fb2k::hwnd_t parent, dsp_preset_edit_callback_v2::ptr callback);
#endif

namespace effects_dsp {

namespace temposhift_common {
    // {C2651CE9-08CE-4F08-871F-14A6C1D7136F}
    static constexpr GUID guid = { 0xc2651ce9, 0x08ce, 0x4f08,
        { 0x87, 0x1f, 0x14, 0xa6, 0xc1, 0xd7, 0x13, 0x6f } };

    struct Params {
        float tempo_pct = 0.0f;
    };

    static void make_preset(const Params& p, dsp_preset& out) {
        dsp_preset_builder builder;
        builder << p.tempo_pct;
        builder.finish(guid, out);
    }

    static Params parse_preset(const dsp_preset& in) {
        Params p;
        try {
            dsp_preset_parser parser(in);
            parser >> p.tempo_pct;
        } catch (exception_io_data const&) {}
        return p;
    }
}

} // namespace effects_dsp
