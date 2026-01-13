# macOS Liquid Glass Design Guide

A comprehensive knowledge base for implementing Apple's Liquid Glass design language in macOS applications, with specific guidance for foobar2000 components.

## Overview

Liquid Glass is Apple's unified design language introduced at WWDC 2025, representing a new functional layer in the UI that floats above content to provide structure and clarity without stealing focus. It uses a translucent material that reflects and refracts surroundings, dynamically transforming based on context.

### Design Evolution

Liquid Glass builds on Apple's design history:
- **Aqua** (Mac OS X) - Original translucent aesthetic
- **iOS 7** - Real-time blurs
- **iPhone X** - Fluid interfaces
- **Dynamic Island** - Adaptive UI elements
- **visionOS** - Immersive transparent interfaces

## Core Principles

### 1. Lensing

The primary visual property of Liquid Glass. Lensing dynamically bends, shapes, and concentrates light in real-time, providing:

- Visual separation between layers
- Communication of depth and layering
- Content visibility while maintaining distinction
- Materialization/dematerialization through gradual light bending modulation

### 2. Concentricity

UI elements nest within container corners, creating harmony between hardware and software:

- Controls, toolbars, and navigation fit concentric with rounded window corners
- Inner radii calculated automatically: `inner_radius = parent_radius - padding`
- Creates visual continuity from window edge to nested controls

### 3. Adaptivity

Liquid Glass responds to its environment:

| Adaptation Type | Behavior |
|-----------------|----------|
| **Content-aware** | Tint, shadows, dynamic range adjust based on underlying content |
| **Size-responsive** | Larger sizes get deeper shadows, pronounced lensing, softer scattering |
| **Environment-aware** | Light from colorful content spills onto surface |
| **Light-source aware** | Responds to device motion and position |

### 4. Hierarchy

Reserve Liquid Glass for the navigation layer only:

```
+------------------------------------------+
|  LIQUID GLASS LAYER (Navigation)         |
|  - Toolbars                              |
|  - Tab bars                              |
|  - Sidebars                              |
|  - Floating controls                     |
+------------------------------------------+
|  CONTENT LAYER                           |
|  - Lists, tables, media                  |
|  - Primary app content                   |
+------------------------------------------+
```

## Variants

### Regular Variant (Default)

Use for most navigation elements:

| Feature | Behavior |
|---------|----------|
| Adaptive behaviors | Active in all contexts |
| Legibility | Automatic regardless of background |
| Size flexibility | Works at any size over any content |
| Light/Dark | Automatically flips based on content |
| Symbols | Auto-flip for contrast |

### Clear Variant (Specialized)

**Use ONLY when ALL three conditions are met:**
1. Element positioned over media-rich content
2. Content layer unaffected by dimming layer
3. Content above is bold and bright

Properties:
- Permanently transparent (no adaptive behaviors)
- Requires explicit dimming layer for legibility
- Allows content vibrancy to interact with glass

## AppKit Implementation

### NSGlassEffectView

Basic glass effect for custom views:

```objc
// Create glass backing for a view
NSGlassEffectView *glassView = [[NSGlassEffectView alloc] init];
glassView.contentView = myContentView;
glassView.cornerRadius = 12;
glassView.tintColor = [NSColor systemBlueColor];  // Optional tint
```

### NSGlassEffectContainerView

For grouping multiple glass elements:

```objc
// Group related glass elements
NSGlassEffectContainerView *container = [[NSGlassEffectContainerView alloc] init];
container.contentView = stackView;
container.spacing = 8;  // Controls joining/separation behavior
```

Benefits:
- Fluid joining/separation based on proximity
- Uniform adaptive appearance across group
- Correct sampling region (prevents glass-on-glass artifacts)
- Performance improvement (single sampling pass)

### NSVisualEffectView Changes

**Remove legacy sidebar materials:**

```objc
// OLD - Remove this from sidebars
NSVisualEffectView *effect = [[NSVisualEffectView alloc] init];
effect.material = NSVisualEffectMaterialSidebar;

// NEW - Let NSSplitViewController handle glass automatically
// No NSVisualEffectView needed for sidebar materials
```

### Toolbar Glass

AppKit automatically applies glass to NSToolbar items:

```objc
// Remove glass from non-interactive items
toolbarItem.bordered = NO;

// Tint with accent color
toolbarItem.style = NSToolbarItemStyleProminent;

// Tint with specific color
toolbarItem.backgroundTintColor = [NSColor systemGreenColor];
```

### Sidebar Implementation

Use NSSplitViewController for automatic glass treatment:

```objc
// Sidebars: floating glass pane above content
// Inspectors: edge-to-edge glass alongside content
// AppKit applies appropriate material based on behavior type

// Allow content to extend beneath sidebar
splitViewItem.automaticallyAdjustsSafeAreaInsets = YES;
```

### Control Customization

```objc
// Glass bezel style
button.bezelStyle = NSBezelStyleGlass;
button.bezelColor = [NSColor systemGreenColor];

// Border shape
button.borderShape = NSButtonBorderShapeCapsule;

// Tint prominence
button.tintProminence = NSControlTintProminenceSecondary;
```

### Compact Metrics

For dense layouts (inspectors, popovers):

```objc
view.prefersCompactControlSizeMetrics = YES;
// Reverts controls to previous macOS sizing
// Inherited down view hierarchy
```

## Scroll Edge Effects

Automatically applied under toolbars, titlebar accessories, and split item accessories:

| Style | Use Case |
|-------|----------|
| **Soft-edge** | Default; progressively fades/blurs content |
| **Hard-edge** | Interactive text, pinned headers; more opaque backing |

## Best Practices

### DO

- Use glass for navigation layer only (toolbars, tab bars, sidebars)
- Keep content layer simple and clear
- Use Regular variant by default
- Test with Reduce Transparency accessibility setting
- Validate contrast ratios after blur (4.5:1 minimum for text)
- Group related glass elements in NSGlassEffectContainerView
- Remove legacy NSVisualEffectView from sidebars

### DON'T

- Stack glass-on-glass (creates clutter and visual confusion)
- Use glass in content areas (lists, tables, media)
- Mix Regular and Clear variants in same view
- Place opaque fills over glass
- Over-tint elements (diminishes emphasis)
- Create large intersections with scrolling content

## Accessibility

### System Accommodations

| Setting | Effect on Liquid Glass |
|---------|------------------------|
| **Reduce Transparency** | Frostier glass, obscures more background |
| **Increase Contrast** | Elements predominantly black/white with contrasting borders |
| **Reduce Motion** | Decreased effect intensity, disabled elastic properties |

### Implementation

Standard AppKit components automatically respect these settings. For custom implementations:

```objc
// Check user preferences
BOOL reduceTransparency = [[NSWorkspace sharedWorkspace] accessibilityDisplayShouldReduceTransparency];
BOOL reduceMotion = [[NSWorkspace sharedWorkspace] accessibilityDisplayShouldReduceMotion];
BOOL increaseContrast = [[NSWorkspace sharedWorkspace] accessibilityDisplayShouldIncreaseContrast];

// Provide fallbacks
if (reduceTransparency) {
    // Use solid backgrounds instead of glass
}
```

### Contrast Requirements

- **Text on glass**: Minimum 4.5:1 contrast ratio after blur
- **Non-text elements**: Minimum 3:1 contrast ratio vs adjacent background
- **Frost values**: 10-25 for accessible translucency (>30 appears "milky")
- **Motion**: Specular highlight amplitude should not exceed 6 pixels

### Testing

1. Enable Accessibility Inspector in Xcode
2. Test with all three accessibility settings enabled
3. Validate in low-contrast environments (direct sunlight scenarios)
4. Test with diverse users in beta phases

## Application to foobar2000 Components

### Where to Use Glass

| Component Area | Glass Usage |
|----------------|-------------|
| Toolbars | Yes - automatic via NSToolbar |
| Sidebars | Yes - automatic via NSSplitViewController |
| Floating controls | Yes - NSGlassEffectView |
| Playlist content | No - keep as content layer |
| Album art | No - content, not navigation |
| Waveform display | No - content layer |
| Track lists | No - content layer |

### Practical Guidelines for Components

1. **SimPlaylist**: No glass in track rows or album headers - these are content
2. **Toolbar controls**: Let NSToolbar handle glass automatically
3. **Floating panels**: Use NSGlassEffectView for hover controls
4. **Context menus**: System handles automatically
5. **Preferences UI**: Avoid glass in form content

### Example: Floating Control

```objc
// A floating playback control overlay
NSGlassEffectView *controlGlass = [[NSGlassEffectView alloc] init];
controlGlass.contentView = playbackButtons;
controlGlass.cornerRadius = 999;  // Capsule shape

// Position as floating overlay above content
[contentView addSubview:controlGlass];
controlGlass.translatesAutoresizingMaskIntoConstraints = NO;
[NSLayoutConstraint activateConstraints:@[
    [controlGlass.centerXAnchor constraintEqualToAnchor:contentView.centerXAnchor],
    [controlGlass.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor constant:-16]
]];
```

## Resources

### Apple Official

- [Meet Liquid Glass - WWDC25](https://developer.apple.com/videos/play/wwdc2025/219/)
- [Get to know the new design system - WWDC25](https://developer.apple.com/videos/play/wwdc2025/356/)
- [Build an AppKit app with the new design - WWDC25](https://developer.apple.com/videos/play/wwdc2025/310/)
- [Human Interface Guidelines: Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- [Apple Design Resources](https://developer.apple.com/design/resources/)

### Key Concepts Summary

| Concept | Meaning |
|---------|---------|
| **Lensing** | Light bending that creates depth/separation |
| **Concentricity** | Nested radii matching container corners |
| **Regular variant** | Adaptive glass for most uses |
| **Clear variant** | Transparent glass for media-rich contexts |
| **Layer economy** | One primary glass sheet per view |

---

## Changelog

| Date | Change |
|------|--------|
| 2026-01-13 | Initial document based on WWDC25 resources |
