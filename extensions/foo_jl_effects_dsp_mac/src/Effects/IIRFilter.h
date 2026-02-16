#pragma once
#include <foobar2000/SDK/dsp.h>

#ifdef __APPLE__
service_ptr ConfigureIIRFilterDSP(fb2k::hwnd_t parent, dsp_preset_edit_callback_v2::ptr callback);
#endif

namespace effects_dsp {

namespace iir_filter_common {
    // {2E238F95-BCC6-4EC1-93D2-3E86B99751BC}
    static constexpr GUID guid = { 0x2e238f95, 0xbcc6, 0x4ec1,
        { 0x93, 0xd2, 0x3e, 0x86, 0xb9, 0x97, 0x51, 0xbc } };

    struct Params {
        int32_t filter_type = 0; // BiquadType enum
        float freq = 1000.0f;
        float q = 0.707f;
        float gain_db = 0.0f;
    };

    static void make_preset(const Params& p, dsp_preset& out) {
        dsp_preset_builder builder;
        builder << p.filter_type << p.freq << p.q << p.gain_db;
        builder.finish(guid, out);
    }

    static Params parse_preset(const dsp_preset& in) {
        Params p;
        try {
            dsp_preset_parser parser(in);
            parser >> p.filter_type >> p.freq >> p.q >> p.gain_db;
        } catch (exception_io_data const&) {}
        return p;
    }
}

} // namespace effects_dsp
