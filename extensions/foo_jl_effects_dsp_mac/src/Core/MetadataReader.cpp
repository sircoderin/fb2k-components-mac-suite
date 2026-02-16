#include "MetadataReader.h"
#include <cstdlib>

namespace effects_dsp {

metadb_handle_ptr MetadataReader::s_current_track;

void MetadataReader::on_new_track(metadb_handle_ptr track) {
    s_current_track = track;
}

float MetadataReader::read_float(const char* field_name, float default_value) {
    if (s_current_track.is_empty()) return default_value;

    const file_info* info = nullptr;
    // Use info reader to get metadata
    metadb_info_container::ptr info_ref;
    if (!s_current_track->get_info_ref(info_ref)) return default_value;
    info = &info_ref->info();

    const char* val = info->meta_get(field_name, 0);
    if (!val) return default_value;

    char* end = nullptr;
    float result = std::strtof(val, &end);
    if (end == val) return default_value;

    return result;
}

} // namespace effects_dsp
