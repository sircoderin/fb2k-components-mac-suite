#pragma once
#include <foobar2000/SDK/dsp.h>

#ifdef __APPLE__
service_ptr ConfigureChorusDSP(fb2k::hwnd_t parent, dsp_preset_edit_callback_v2::ptr callback);
#endif

namespace effects_dsp {

namespace chorus_common {
    // {621A5048-F2BB-4CE1-9395-FA610FE4E8C1}
    static constexpr GUID guid = { 0x621a5048, 0xf2bb, 0x4ce1,
        { 0x93, 0x95, 0xfa, 0x61, 0x0f, 0xe4, 0xe8, 0xc1 } };

    struct Params {
        float delay_ms = 20.0f;
        float rate = 0.5f;
        float depth = 0.5f;
        float feedback = 0.0f;
        float wet_dry = 0.5f;
    };

    static void make_preset(const Params& p, dsp_preset& out) {
        dsp_preset_builder builder;
        builder << p.delay_ms << p.rate << p.depth << p.feedback << p.wet_dry;
        builder.finish(guid, out);
    }

    static Params parse_preset(const dsp_preset& in) {
        Params p;
        try {
            dsp_preset_parser parser(in);
            parser >> p.delay_ms >> p.rate >> p.depth >> p.feedback >> p.wet_dry;
        } catch (exception_io_data const&) {}
        return p;
    }
}

} // namespace effects_dsp
