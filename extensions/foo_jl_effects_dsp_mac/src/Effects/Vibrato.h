#pragma once
#include <foobar2000/SDK/dsp.h>

#ifdef __APPLE__
service_ptr ConfigureVibratoDSP(fb2k::hwnd_t parent, dsp_preset_edit_callback_v2::ptr callback);
#endif

namespace effects_dsp {

namespace vibrato_common {
    // {31219EB8-B0DD-4119-83D7-6F3FF302D800}
    static constexpr GUID guid = { 0x31219eb8, 0xb0dd, 0x4119,
        { 0x83, 0xd7, 0x6f, 0x3f, 0xf3, 0x02, 0xd8, 0x00 } };

    struct Params {
        float rate = 5.0f;
        float depth = 0.5f;
    };

    static void make_preset(const Params& p, dsp_preset& out) {
        dsp_preset_builder builder;
        builder << p.rate << p.depth;
        builder.finish(guid, out);
    }

    static Params parse_preset(const dsp_preset& in) {
        Params p;
        try {
            dsp_preset_parser parser(in);
            parser >> p.rate >> p.depth;
        } catch (exception_io_data const&) {}
        return p;
    }
}

} // namespace effects_dsp
