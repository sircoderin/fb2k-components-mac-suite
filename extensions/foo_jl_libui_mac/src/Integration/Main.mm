#include "../fb2k_sdk.h"
#include "../../../../shared/common_about.h"
#include "../../../../shared/version.h"

#import "../UI/LibUIController.h"
#import "LibUICallbacks.h"

JL_COMPONENT_ABOUT(
    "LibUI",
    LIBUI_VERSION,
    "Album grid library browser for foobar2000 macOS\n\n"
    "Features:\n"
    "- Album grid with cover art thumbnails\n"
    "- In-place track list expansion\n"
    "- Search/filter with library search syntax\n"
    "- Drag & drop to playlists and queue\n"
    "- Context menu with playlist/queue actions\n"
    "- Keyboard shortcuts (Q to queue, Enter to send)\n"
    "- Dark mode support"
);

VALIDATE_COMPONENT_FILENAME("foo_jl_libui.component");

namespace {
    // {B4E8F3A2-9C5D-4E6B-AF7E-2D3C4B5A6E7F}
    static const GUID g_guid_libui = {
        0xB4E8F3A2, 0x9C5D, 0x4E6B,
        {0xAF, 0x7E, 0x2D, 0x3C, 0x4B, 0x5A, 0x6E, 0x7F}
    };

    class libui_ui_element : public ui_element_mac {
    public:
        service_ptr instantiate(service_ptr arg) override {
            @autoreleasepool {
                LibUIController* controller = [[LibUIController alloc] init];
                LibUICallbackManager::instance().registerController(controller);
                return fb2k::wrapNSObject(controller);
            }
        }

        bool match_name(const char* name) override {
            return strcmp(name, "LibUI") == 0 ||
                   strcmp(name, "libui") == 0 ||
                   strcmp(name, "lib_ui") == 0 ||
                   strcmp(name, "Library UI") == 0 ||
                   strcmp(name, "foo_jl_libui") == 0 ||
                   strcmp(name, "jl_libui") == 0;
        }

        fb2k::stringRef get_name() override {
            return fb2k::makeString("LibUI");
        }

        GUID get_guid() override {
            return g_guid_libui;
        }
    };

    FB2K_SERVICE_FACTORY(libui_ui_element);
}

class libui_init : public initquit {
public:
    void on_init() override {
        LibUICallbackManager::instance().initCallbacks();
        console::info("[LibUI] Component initialized");
    }

    void on_quit() override {
        LibUICallbackManager::instance().shutdownCallbacks();
        console::info("[LibUI] Component shutting down");
    }
};

FB2K_SERVICE_FACTORY(libui_init);
