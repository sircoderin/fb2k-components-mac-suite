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

// Size variants for display density
enum class SizeVariant : int {
    Compact = 0,
    Normal = 1,
    Large = 2
};

// Accent color modes for column header bar
enum class AccentMode : int {
    None = 0,
    Tinted = 1
};

// Row dimensions based on size variant
inline CGFloat rowHeight(SizeVariant size) {
    switch (size) {
        case SizeVariant::Compact: return 19.0;
        case SizeVariant::Large:   return 26.0;
        default:                   return 22.0;
    }
}

inline CGFloat rowFontSize(SizeVariant size) {
    switch (size) {
        case SizeVariant::Compact: return 12.0;
        case SizeVariant::Large:   return 14.0;
        default:                   return 13.0;
    }
}

// Column header dimensions based on size variant
inline CGFloat headerHeight(SizeVariant size) {
    switch (size) {
        case SizeVariant::Compact: return 22.0;
        case SizeVariant::Large:   return 34.0;
        default:                   return 28.0;
    }
}

inline CGFloat headerFontSize(SizeVariant size) {
    switch (size) {
        case SizeVariant::Compact: return 11.0;
        case SizeVariant::Large:   return 13.0;
        default:                   return 12.0;
    }
}

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

// Appearance detection
inline BOOL isDarkMode() {
    NSAppearance *appearance = [NSApp effectiveAppearance];
    return [appearance bestMatchFromAppearancesWithNames:
            @[NSAppearanceNameDarkAqua, NSAppearanceNameAqua]] == NSAppearanceNameDarkAqua;
}

inline BOOL shouldReduceTransparency() {
    return [[NSWorkspace sharedWorkspace] accessibilityDisplayShouldReduceTransparency];
}

// Color blending helper
inline NSColor* blendColors(NSColor* base, NSColor* overlay, CGFloat factor) {
    NSColor *baseRGB = [base colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
    NSColor *overlayRGB = [overlay colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
    if (!baseRGB || !overlayRGB) return base;
    CGFloat r = baseRGB.redComponent * (1 - factor) + overlayRGB.redComponent * factor;
    CGFloat g = baseRGB.greenComponent * (1 - factor) + overlayRGB.greenComponent * factor;
    CGFloat b = baseRGB.blueComponent * (1 - factor) + overlayRGB.blueComponent * factor;
    return [NSColor colorWithSRGBRed:r green:g blue:b alpha:1.0];
}

// Background colors
inline NSColor* backgroundColor() {
    return [NSColor controlBackgroundColor];
}

inline NSColor* alternateRowColor() {
    return [[NSColor controlBackgroundColor] blendedColorWithFraction:0.03
                                                              ofColor:[NSColor labelColor]];
}

// Header colors (accent and glass aware)
inline NSColor* headerBackgroundColor(AccentMode accent = AccentMode::None) {
    NSColor *base = [NSColor controlBackgroundColor];
    if (accent == AccentMode::Tinted) {
        return blendColors(base, [NSColor controlAccentColor], 0.2);
    }
    return base;
}

inline NSColor* headerBackgroundColorForGlass(AccentMode accent = AccentMode::None) {
    if (shouldReduceTransparency()) {
        return [headerBackgroundColor(accent) colorWithAlphaComponent:0.8];
    }
    if (accent == AccentMode::Tinted) {
        return [[NSColor controlAccentColor] colorWithAlphaComponent:0.15];
    }
    return nil;
}

inline NSColor* headerTopHighlightColor(AccentMode accent = AccentMode::None) {
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
    return nil;
}

inline NSColor* headerBottomBorderColor() {
    return [NSColor separatorColor];
}

inline NSColor* headerDividerColor() {
    return [NSColor separatorColor];
}

// Selection colors
inline NSColor* selectedBackgroundColor() {
    return [NSColor selectedContentBackgroundColor];
}

// Text colors
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

// Separator and indicator colors
inline NSColor* separatorColor() {
    return [NSColor separatorColor];
}

inline NSColor* dropIndicatorColor() {
    return [NSColor controlAccentColor];
}

inline NSColor* focusRingColor() {
    return [NSColor selectedContentBackgroundColor];
}

// Glass container helpers
inline NSView* createGlassContainer(NSRect frame) {
    NSVisualEffectView *effectView = [[NSVisualEffectView alloc] initWithFrame:frame];
    effectView.material = NSVisualEffectMaterialSidebar;
    effectView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    effectView.state = NSVisualEffectStateActive;
    return effectView;
}

inline void configureScrollViewForGlass(NSScrollView *scrollView, BOOL glass) {
    if (glass) {
        scrollView.drawsBackground = NO;
        scrollView.backgroundColor = [NSColor clearColor];
    } else {
        scrollView.drawsBackground = YES;
        scrollView.backgroundColor = [NSColor controlBackgroundColor];
    }
}

// Font helpers
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
    return [NSFont systemFontOfSize:kStatusBarFontSize];
}

} // namespace fb2k_ui
