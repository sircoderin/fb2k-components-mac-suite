#pragma once

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface LibUIController : NSViewController

- (void)handleLibraryItemsAdded;
- (void)handleLibraryItemsRemoved;
- (void)handleLibraryItemsModified;

@end

NS_ASSUME_NONNULL_END
