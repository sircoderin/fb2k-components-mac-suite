#pragma once
#include <foobar2000/SDK/dsp.h>

#ifdef __APPLE__
service_ptr ConfigureTremoloDSP(fb2k::hwnd_t parent, dsp_preset_edit_callback_v2::ptr callback);
#endif

namespace effects_dsp {

namespace tremolo_common {
    // {0EF6493A-650E-46EC-82EB-9E6B9CC833E7}
    static constexpr GUID guid = { 0x0ef6493a, 0x650e, 0x46ec,
        { 0x82, 0xeb, 0x9e, 0x6b, 0x9c, 0xc8, 0x33, 0xe7 } };

    struct Params {
        float freq = 5.0f;
        float depth = 0.5f;
    };

    static void make_preset(const Params& p, dsp_preset& out) {
        dsp_preset_builder builder;
        builder << p.freq << p.depth;
        builder.finish(guid, out);
    }

    static Params parse_preset(const dsp_preset& in) {
        Params p;
        try {
            dsp_preset_parser parser(in);
            parser >> p.freq >> p.depth;
        } catch (exception_io_data const&) {}
        return p;
    }
}

} // namespace effects_dsp
