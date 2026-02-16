#pragma once
#include <foobar2000/SDK/dsp.h>

#ifdef __APPLE__
service_ptr ConfigurePhaserDSP(fb2k::hwnd_t parent, dsp_preset_edit_callback_v2::ptr callback);
#endif

namespace effects_dsp {

namespace phaser_common {
    // {1C290907-4B8D-4EA3-9C16-4566FBD70857}
    static constexpr GUID guid = { 0x1c290907, 0x4b8d, 0x4ea3,
        { 0x9c, 0x16, 0x45, 0x66, 0xfb, 0xd7, 0x08, 0x57 } };

    struct Params {
        float rate = 0.5f;
        float depth = 0.7f;
        float feedback = 0.7f;
        int32_t stages = 6;
        float wet_dry = 0.5f;
    };

    static void make_preset(const Params& p, dsp_preset& out) {
        dsp_preset_builder builder;
        builder << p.rate << p.depth << p.feedback << p.stages << p.wet_dry;
        builder.finish(guid, out);
    }

    static Params parse_preset(const dsp_preset& in) {
        Params p;
        try {
            dsp_preset_parser parser(in);
            parser >> p.rate >> p.depth >> p.feedback >> p.stages >> p.wet_dry;
        } catch (exception_io_data const&) {}
        return p;
    }
}

} // namespace effects_dsp
