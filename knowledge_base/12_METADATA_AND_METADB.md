# Metadata and metadb Operations

This document covers how foobar2000 handles track metadata, the metadb system, and how to programmatically trigger metadata reload.

## 1. Overview

The **metadb** (metadata database) is foobar2000's central system for storing and caching track information. Every track in foobar2000 is represented by a `metadb_handle_ptr` which provides access to cached metadata.

### Key Components

| Component | Purpose |
|-----------|---------|
| `metadb_handle_ptr` | Smart pointer to a track's database entry |
| `file_info` | Contains all metadata tags + technical info |
| `metadb_io` | Service for reading/writing metadata |
| `metadb_io_v2` | Extended service with async operations |

## 2. What Happens When Tracks Are Added

When tracks are added to a playlist:

1. Files are passed through `playlist_incoming_item_filter`
2. `metadb_io::load_info_multi()` or `load_info_async()` is called
3. Input decoders read file tags (ID3, Vorbis comments, etc.)
4. Results cached in metadb (memory + persistent database)
5. Playlist callbacks fire with `metadb_handle_ptr` objects

### Storage Location

- In-memory cache within metadb handles
- Persistent database files in `~/Library/foobar2000-v2/`

## 3. Accessing Metadata

### Pattern 1: Async (for UI, non-blocking)

```cpp
file_info_impl info;
track->get_info_async(info);  // Returns cached data immediately

double duration = info.get_length();
int samplerate = info.info_get_int("samplerate");
const char* codec = info.info_get("codec");
```

### Pattern 2: Reference (for extraction)

```cpp
metadb_info_container::ptr info;
track->get_info_ref(info);
if (info.is_valid()) {
    const file_info& fi = info->info();
    const char* artist = fi.meta_get("artist", 0);
    int tracknum = fi.meta_get_int("tracknumber");
}
```

### Pattern 3: Title Formatting

```cpp
titleformat_object::ptr script;
static_api_ptr_t<titleformat_compiler>()->compile_safe(script, "%artist% - %title%");

pfc::string8 result;
track->format_title(nullptr, result, script, nullptr);
```

## 4. Triggering Metadata Reload

### Option A: Built-in Context Menu Command

```cpp
#include <SDK/menu_helpers.h>

metadb_handle_list tracks;
// ... populate tracks ...

// Same as right-click -> "Reload info"
standard_commands::context_reload_info(tracks);
```

### Option B: metadb_io_v2 (Full Control)

```cpp
#include <SDK/metadb.h>

metadb_handle_list tracks;
// ... populate tracks ...

metadb_io_v2::get()->load_info_async(
    tracks,
    metadb_io::load_info_force,      // Force re-read from file
    core_api::get_main_window(),
    metadb_io_v2::op_flag_background,  // No modal dialog
    completion_notify_ptr()          // Optional callback
);
```

### Load Info Types

| Type | Behavior |
|------|----------|
| `load_info_default` | Use cached if available |
| `load_info_force` | Always re-read from file |
| `load_info_check_if_changed` | Re-read only if file timestamp changed |

### Operation Flags

| Flag | Effect |
|------|--------|
| `op_flag_background` | Run in background, no modal progress dialog |
| `op_flag_delay_ui` | Delay UI updates until operation complete |

## 5. Practical Example: Reload Selected Tracks

```cpp
void reloadSelectedTrackInfo() {
    auto pm = playlist_manager::get();
    t_size playlist = pm->get_active_playlist();

    metadb_handle_list tracks;
    pm->playlist_get_selected_items(playlist, tracks);

    if (tracks.get_count() > 0) {
        // Background reload - no modal dialog
        metadb_io_v2::get()->load_info_async(
            tracks,
            metadb_io::load_info_force,
            core_api::get_main_window(),
            metadb_io_v2::op_flag_background,
            nullptr
        );
    }
}
```

## 6. Receiving Metadata Change Notifications

Register a `metadb_io_callback` to be notified when metadata changes:

```cpp
class my_metadb_callback : public metadb_io_callback {
public:
    void on_changed_sorted(metadb_handle_list_cref items, bool fromhook) override {
        // Items' metadata has been updated
        // Refresh UI displays as needed
    }
};

static service_factory_single_t<my_metadb_callback> g_my_callback;
```

For playlist-specific notifications, use `playlist_callback_single::on_items_modified()`.

## 7. Dispatching Refresh Notifications

If your component provides custom title-formatting fields via `metadb_display_field_provider`, you MUST call `dispatch_refresh()` when your data changes:

```cpp
metadb_handle_list changed_items;
// ... populate with affected tracks ...

metadb_io::get()->dispatch_refresh(changed_items);
```

Without this, playlists and other UI won't update to reflect your changes.

## 8. Thread Safety

| Operation | Thread Safety |
|-----------|---------------|
| `get_info_async()` | Safe from any thread |
| `format_title()` | Safe for reading |
| `load_info_async()` | Main thread only |
| `dispatch_refresh()` | Main thread only |
| Playlist operations | Main thread only |

## 9. Common Metadata Fields

### Tags (via `meta_get`)

- `artist`, `album`, `title`, `date`, `genre`
- `tracknumber`, `discnumber`, `totaltracks`
- `album artist`, `composer`, `performer`

### Technical Info (via `info_get`)

- `samplerate` - Sample rate in Hz
- `channels` - Number of audio channels
- `bitrate` - Bitrate in kbps
- `codec` - Codec name string
- `encoding` - Encoding type (lossy/lossless)

### Duration

```cpp
double seconds = info.get_length();
```

## 10. Related Documentation

- `03_SDK_SERVICE_PATTERNS.md` - Core service patterns
- `04_UI_ELEMENT_IMPLEMENTATION.md` - UI callbacks
- foobar2000 SDK: `metadb.h`, `metadb_handle.h`, `file_info.h`
