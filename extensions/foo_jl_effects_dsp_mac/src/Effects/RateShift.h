#pragma once
#include <foobar2000/SDK/dsp.h>

#ifdef __APPLE__
service_ptr ConfigureRateShiftDSP(fb2k::hwnd_t parent, dsp_preset_edit_callback_v2::ptr callback);
#endif

namespace effects_dsp {

namespace rateshift_common {
    // {B88692A2-EFC3-4FBB-962D-1656D7206A16}
    static constexpr GUID guid = { 0xb88692a2, 0xefc3, 0x4fbb,
        { 0x96, 0x2d, 0x16, 0x56, 0xd7, 0x20, 0x6a, 0x16 } };

    struct Params {
        float rate_pct = 0.0f;
    };

    static void make_preset(const Params& p, dsp_preset& out) {
        dsp_preset_builder builder;
        builder << p.rate_pct;
        builder.finish(guid, out);
    }

    static Params parse_preset(const dsp_preset& in) {
        Params p;
        try {
            dsp_preset_parser parser(in);
            parser >> p.rate_pct;
        } catch (exception_io_data const&) {}
        return p;
    }
}

} // namespace effects_dsp
