//
//  UIStyles.h
//  Shared UI styles for foobar2000 macOS components
//
//  Common visual definitions to ensure consistent look across:
//  - foo_jl_simplaylist_mac
//  - foo_jl_queue_manager
//  - Other list-based UI components
//

#pragma once

#import <Cocoa/Cocoa.h>

namespace fb2k_ui {

// Layout constants
static const CGFloat kDefaultRowHeight = 22.0;
static const CGFloat kDefaultHeaderHeight = 22.0;
static const CGFloat kHeaderTextPadding = 6.0;
static const CGFloat kCellTextPadding = 4.0;
static const CGFloat kResizeHandleWidth = 6.0;

// Font sizes
static const CGFloat kHeaderFontSize = 11.0;
static const CGFloat kRowFontSize = 12.0;
static const CGFloat kStatusBarFontSize = 11.0;

// Color helpers - inline functions for Objective-C++ compatibility
inline NSColor* backgroundColor() {
    return [NSColor controlBackgroundColor];
}

inline NSColor* alternateRowColor() {
    return [[NSColor controlBackgroundColor] blendedColorWithFraction:0.03
                                                              ofColor:[NSColor labelColor]];
}

inline NSColor* headerBackgroundColor() {
    // Match native NSTableHeaderView - use control background (same as content area)
    return [NSColor controlBackgroundColor];
}

inline NSColor* headerTopHighlightColor() {
    // Subtle top highlight line
    NSAppearance *appearance = [NSApp effectiveAppearance];
    BOOL isDark = [appearance bestMatchFromAppearancesWithNames:
                   @[NSAppearanceNameDarkAqua, NSAppearanceNameAqua]] == NSAppearanceNameDarkAqua;
    if (isDark) {
        return [[NSColor whiteColor] colorWithAlphaComponent:0.08];
    } else {
        return [[NSColor whiteColor] colorWithAlphaComponent:0.5];
    }
}

inline NSColor* headerBottomBorderColor() {
    // Bottom border - slightly darker than separator
    NSAppearance *appearance = [NSApp effectiveAppearance];
    BOOL isDark = [appearance bestMatchFromAppearancesWithNames:
                   @[NSAppearanceNameDarkAqua, NSAppearanceNameAqua]] == NSAppearanceNameDarkAqua;
    if (isDark) {
        return [[NSColor blackColor] colorWithAlphaComponent:0.4];
    } else {
        return [[NSColor blackColor] colorWithAlphaComponent:0.15];
    }
}

inline NSColor* headerDividerColor() {
    // Column dividers
    return [NSColor separatorColor];
}

inline NSColor* selectedBackgroundColor() {
    return [NSColor selectedContentBackgroundColor];
}

inline NSColor* textColor() {
    return [NSColor labelColor];
}

inline NSColor* selectedTextColor() {
    return [NSColor selectedMenuItemTextColor];
}

inline NSColor* secondaryTextColor() {
    return [NSColor secondaryLabelColor];
}

inline NSColor* separatorColor() {
    return [NSColor separatorColor];
}

inline NSColor* dropIndicatorColor() {
    return [NSColor systemBlueColor];
}

// Font helpers
inline NSFont* headerFont() {
    return [NSFont systemFontOfSize:kHeaderFontSize weight:NSFontWeightMedium];
}

inline NSFont* rowFont() {
    return [NSFont systemFontOfSize:kRowFontSize];
}

inline NSFont* monospacedDigitFont() {
    return [NSFont monospacedDigitSystemFontOfSize:kRowFontSize weight:NSFontWeightRegular];
}

inline NSFont* statusBarFont() {
    return [NSFont systemFontOfSize:kStatusBarFontSize];
}

} // namespace fb2k_ui
