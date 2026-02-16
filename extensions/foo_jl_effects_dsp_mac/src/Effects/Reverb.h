#pragma once
#include <foobar2000/SDK/dsp.h>

#ifdef __APPLE__
service_ptr ConfigureReverbDSP(fb2k::hwnd_t parent, dsp_preset_edit_callback_v2::ptr callback);
#endif

namespace effects_dsp {

namespace reverb_common {
    // {B4474EA6-FB9F-449C-81BB-4B9B84AD6C47}
    static constexpr GUID guid = { 0xb4474ea6, 0xfb9f, 0x449c,
        { 0x81, 0xbb, 0x4b, 0x9b, 0x84, 0xad, 0x6c, 0x47 } };

    struct Params {
        float room_size = 0.5f;
        float damping = 0.5f;
        float wet = 0.3f;
        float dry = 1.0f;
        float width = 1.0f;
    };

    static void make_preset(const Params& p, dsp_preset& out) {
        dsp_preset_builder builder;
        builder << p.room_size << p.damping << p.wet << p.dry << p.width;
        builder.finish(guid, out);
    }

    static Params parse_preset(const dsp_preset& in) {
        Params p;
        try {
            dsp_preset_parser parser(in);
            parser >> p.room_size >> p.damping >> p.wet >> p.dry >> p.width;
        } catch (exception_io_data const&) {}
        return p;
    }
}

} // namespace effects_dsp
