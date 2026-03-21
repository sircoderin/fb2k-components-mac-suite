#import "LibUICallbacks.h"
#import "../UI/LibUIController.h"
#import <mutex>

static std::mutex g_controllersMutex;
static NSHashTable<LibUIController *> *g_controllers;

LibUICallbackManager& LibUICallbackManager::instance() {
    static LibUICallbackManager manager;
    return manager;
}

void LibUICallbackManager::registerController(LibUIController* controller) {
    std::lock_guard<std::mutex> lock(g_controllersMutex);
    if (!g_controllers) {
        g_controllers = [NSHashTable weakObjectsHashTable];
    }
    [g_controllers addObject:controller];
}

void LibUICallbackManager::unregisterController(LibUIController* controller) {
    std::lock_guard<std::mutex> lock(g_controllersMutex);
    [g_controllers removeObject:controller];
}

void LibUICallbackManager::onLibraryItemsAdded(metadb_handle_list_cref items) {
    dispatch_async(dispatch_get_main_queue(), ^{
        std::lock_guard<std::mutex> lock(g_controllersMutex);
        for (LibUIController *c in g_controllers) {
            [c handleLibraryItemsAdded];
        }
    });
}

void LibUICallbackManager::onLibraryItemsRemoved(metadb_handle_list_cref items) {
    dispatch_async(dispatch_get_main_queue(), ^{
        std::lock_guard<std::mutex> lock(g_controllersMutex);
        for (LibUIController *c in g_controllers) {
            [c handleLibraryItemsRemoved];
        }
    });
}

void LibUICallbackManager::onLibraryItemsModified(metadb_handle_list_cref items) {
    dispatch_async(dispatch_get_main_queue(), ^{
        std::lock_guard<std::mutex> lock(g_controllersMutex);
        for (LibUIController *c in g_controllers) {
            [c handleLibraryItemsModified];
        }
    });
}

void LibUICallbackManager_registerController(LibUIController* controller) {
    LibUICallbackManager::instance().registerController(controller);
}

void LibUICallbackManager_unregisterController(LibUIController* controller) {
    LibUICallbackManager::instance().unregisterController(controller);
}

class libui_library_callback : public library_callback {
public:
    void on_items_added(metadb_handle_list_cref items) override {
        LibUICallbackManager::instance().onLibraryItemsAdded(items);
    }
    void on_items_removed(metadb_handle_list_cref items) override {
        LibUICallbackManager::instance().onLibraryItemsRemoved(items);
    }
    void on_items_modified(metadb_handle_list_cref items) override {
        LibUICallbackManager::instance().onLibraryItemsModified(items);
    }
};

FB2K_SERVICE_FACTORY(libui_library_callback);

void LibUICallbackManager::initCallbacks() {}
void LibUICallbackManager::shutdownCallbacks() {}
