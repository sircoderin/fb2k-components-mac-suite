#pragma once
#include <foobar2000/SDK/dsp.h>

namespace effects_dsp {

// Reads a float value from the currently playing track's metadata.
// Used by SoundTouch effects to override parameters via tags.
class MetadataReader {
public:
    // Read a named metadata field as a float.
    // Returns default_value if the field is not present or cannot be parsed.
    static float read_float(const char* field_name, float default_value);

    // Notify that a new track has started (call from on_chunk when need_track_change_mark is set).
    static void on_new_track(metadb_handle_ptr track);

private:
    static metadb_handle_ptr s_current_track;
};

} // namespace effects_dsp
