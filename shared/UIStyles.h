//
//  UIStyles.h
//  Shared UI styles for foobar2000 macOS components
//
//  Common visual definitions to ensure consistent look across:
//  - foo_jl_simplaylist_mac
//  - foo_jl_queue_manager
//  - Other list-based UI components
//
//  Supports:
//  - Size variants (Compact, Normal, Large)
//  - Accent colors (None, Tinted)
//  - Glass (transparent) backgrounds
//

#pragma once

#import <Cocoa/Cocoa.h>

namespace fb2k_ui {

// MARK: - Size Variants

enum class SizeVariant : int {
    Compact = 0,
    Normal = 1,
    Large = 2
};

// MARK: - Accent Color Modes

enum class AccentMode : int {
    None = 0,
    Tinted = 1
};

// MARK: - Row Dimensions (for track lists)

inline CGFloat rowHeight(SizeVariant size) {
    switch (size) {
        case SizeVariant::Compact: return 19.0;
        case SizeVariant::Large:   return 26.0;
        default:                   return 22.0;  // Normal
    }
}

inline CGFloat rowFontSize(SizeVariant size) {
    switch (size) {
        case SizeVariant::Compact: return 12.0;
        case SizeVariant::Large:   return 14.0;
        default:                   return 13.0;  // Normal
    }
}

// MARK: - Header Dimensions (for column headers)

inline CGFloat headerHeight(SizeVariant size) {
    switch (size) {
        case SizeVariant::Compact: return 22.0;
        case SizeVariant::Large:   return 34.0;
        default:                   return 28.0;  // Normal
    }
}

inline CGFloat headerFontSize(SizeVariant size) {
    switch (size) {
        case SizeVariant::Compact: return 11.0;
        case SizeVariant::Large:   return 13.0;
        default:                   return 12.0;  // Normal
    }
}

// MARK: - Layout Constants

static const CGFloat kHeaderTextPadding = 6.0;
static const CGFloat kCellTextPadding = 4.0;
static const CGFloat kResizeHandleWidth = 6.0;

// MARK: - Appearance Detection

inline BOOL isDarkMode() {
    NSAppearance *appearance = [NSApp effectiveAppearance];
    return [appearance bestMatchFromAppearancesWithNames:
            @[NSAppearanceNameDarkAqua, NSAppearanceNameAqua]] == NSAppearanceNameDarkAqua;
}

inline BOOL shouldReduceTransparency() {
    return [[NSWorkspace sharedWorkspace] accessibilityDisplayShouldReduceTransparency];
}

// MARK: - Color Blending

inline NSColor* blendColors(NSColor* base, NSColor* overlay, CGFloat factor) {
    NSColor *baseRGB = [base colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
    NSColor *overlayRGB = [overlay colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
    if (!baseRGB || !overlayRGB) return base;

    CGFloat r = baseRGB.redComponent * (1 - factor) + overlayRGB.redComponent * factor;
    CGFloat g = baseRGB.greenComponent * (1 - factor) + overlayRGB.greenComponent * factor;
    CGFloat b = baseRGB.blueComponent * (1 - factor) + overlayRGB.blueComponent * factor;
    return [NSColor colorWithSRGBRed:r green:g blue:b alpha:1.0];
}

// MARK: - Background Colors

inline NSColor* backgroundColor() {
    return [NSColor controlBackgroundColor];
}

inline NSColor* clearBackgroundColor() {
    return [NSColor clearColor];
}

inline NSColor* alternateRowColor() {
    return [[NSColor controlBackgroundColor] blendedColorWithFraction:0.03
                                                              ofColor:[NSColor labelColor]];
}

// MARK: - Header Colors (accent and glass aware)

inline NSColor* headerBackgroundColor(AccentMode accent = AccentMode::None) {
    NSColor *base = [NSColor controlBackgroundColor];
    if (accent == AccentMode::Tinted) {
        return blendColors(base, [NSColor controlAccentColor], 0.2);
    }
    return base;
}

inline NSColor* headerBackgroundColorForGlass(AccentMode accent = AccentMode::None) {
    if (shouldReduceTransparency()) {
        // Accessibility: use semi-opaque when reduce transparency is on
        NSColor *base = headerBackgroundColor(accent);
        return [base colorWithAlphaComponent:0.8];
    }
    if (accent == AccentMode::Tinted) {
        // Tinted glass: semi-transparent accent blend
        return [[NSColor controlAccentColor] colorWithAlphaComponent:0.15];
    }
    return nil;  // nil means don't draw - let glass show through
}

inline NSColor* headerTopHighlightColor(AccentMode accent = AccentMode::None) {
    // No highlight when accent is active
    if (accent != AccentMode::None) return nil;

    if (isDarkMode()) {
        return [[NSColor whiteColor] colorWithAlphaComponent:0.08];
    } else {
        return [[NSColor whiteColor] colorWithAlphaComponent:0.5];
    }
}

inline NSColor* headerTopHighlightColorForGlass(AccentMode accent = AccentMode::None) {
    if (accent != AccentMode::None) return nil;
    if (shouldReduceTransparency()) {
        return headerTopHighlightColor(accent);
    }
    return nil;  // No highlight on glass
}

inline NSColor* headerBottomBorderColor() {
    return [NSColor separatorColor];
}

inline NSColor* headerDividerColor() {
    return [NSColor separatorColor];
}

// MARK: - Selection Colors

inline NSColor* selectedBackgroundColor() {
    return [NSColor selectedContentBackgroundColor];
}

inline NSColor* selectedBackgroundColorForGlass() {
    return [NSColor selectedContentBackgroundColor];
}

// MARK: - Text Colors

inline NSColor* textColor() {
    return [NSColor labelColor];
}

inline NSColor* selectedTextColor() {
    return [NSColor selectedMenuItemTextColor];
}

inline NSColor* secondaryTextColor() {
    return [NSColor secondaryLabelColor];
}

inline NSColor* headerTextColor() {
    return [NSColor secondaryLabelColor];
}

// MARK: - Separator and Indicator Colors

inline NSColor* separatorColor() {
    return [NSColor separatorColor];
}

inline NSColor* dropIndicatorColor() {
    return [NSColor controlAccentColor];
}

inline NSColor* focusRingColor() {
    return [NSColor selectedContentBackgroundColor];
}

// MARK: - Font Helpers

inline NSFont* headerFont(SizeVariant size = SizeVariant::Normal) {
    return [NSFont systemFontOfSize:headerFontSize(size) weight:NSFontWeightRegular];
}

inline NSFont* rowFont(SizeVariant size = SizeVariant::Normal) {
    return [NSFont systemFontOfSize:rowFontSize(size)];
}

inline NSFont* monospacedDigitFont(SizeVariant size = SizeVariant::Normal) {
    return [NSFont monospacedDigitSystemFontOfSize:rowFontSize(size) weight:NSFontWeightRegular];
}

inline NSFont* statusBarFont() {
    return [NSFont systemFontOfSize:11.0];
}

// MARK: - Glass Container Setup

inline NSVisualEffectView* createGlassContainer(NSRect frame) {
    NSVisualEffectView* effectView = [[NSVisualEffectView alloc] initWithFrame:frame];
    effectView.material = NSVisualEffectMaterialSidebar;
    effectView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    effectView.state = NSVisualEffectStateFollowsWindowActiveState;
    return effectView;
}

inline void configureScrollViewForGlass(NSScrollView* scrollView, BOOL isGlass) {
    scrollView.drawsBackground = !isGlass;
    scrollView.contentView.drawsBackground = !isGlass;
    if (!isGlass) {
        scrollView.backgroundColor = backgroundColor();
        scrollView.contentView.backgroundColor = backgroundColor();
    }
}

inline void configureTableViewForGlass(NSTableView* tableView, BOOL isGlass) {
    tableView.backgroundColor = isGlass ? clearBackgroundColor() : backgroundColor();
    tableView.usesAlternatingRowBackgroundColors = NO;
}

} // namespace fb2k_ui
