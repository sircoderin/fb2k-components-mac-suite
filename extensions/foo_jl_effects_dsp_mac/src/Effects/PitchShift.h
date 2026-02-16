#pragma once
#include <foobar2000/SDK/dsp.h>

#ifdef __APPLE__
service_ptr ConfigurePitchShiftDSP(fb2k::hwnd_t parent, dsp_preset_edit_callback_v2::ptr callback);
#endif

namespace effects_dsp {

namespace pitchshift_common {
    // {E420DF53-927C-46E7-8021-B260179B4793}
    static constexpr GUID guid = { 0xe420df53, 0x927c, 0x46e7,
        { 0x80, 0x21, 0xb2, 0x60, 0x17, 0x9b, 0x47, 0x93 } };

    struct Params {
        float pitch_semitones = 0.0f;
    };

    static void make_preset(const Params& p, dsp_preset& out) {
        dsp_preset_builder builder;
        builder << p.pitch_semitones;
        builder.finish(guid, out);
    }

    static Params parse_preset(const dsp_preset& in) {
        Params p;
        try {
            dsp_preset_parser parser(in);
            parser >> p.pitch_semitones;
        } catch (exception_io_data const&) {}
        return p;
    }
}

} // namespace effects_dsp
