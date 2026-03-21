#pragma once

#import <Cocoa/Cocoa.h>
#include "../fb2k_sdk.h"

@class LibUIController;

class LibUICallbackManager {
public:
    static LibUICallbackManager& instance();

    void registerController(LibUIController* controller);
    void unregisterController(LibUIController* controller);

    void onLibraryItemsAdded(metadb_handle_list_cref items);
    void onLibraryItemsRemoved(metadb_handle_list_cref items);
    void onLibraryItemsModified(metadb_handle_list_cref items);

    void initCallbacks();
    void shutdownCallbacks();

private:
    LibUICallbackManager() = default;
};

void LibUICallbackManager_registerController(LibUIController* controller);
void LibUICallbackManager_unregisterController(LibUIController* controller);
