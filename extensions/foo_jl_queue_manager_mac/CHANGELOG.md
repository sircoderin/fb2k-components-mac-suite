# Changelog

## [1.1.0] - 2026-01-22

### Changed

- **Custom Header Bar**: Replaced NSTableHeaderView with standalone NSView header bar matching SimPlaylist's architecture
- **Glass/Vibrancy Refactor**: Uses shared UIStyles.h glass helpers (`createGlassContainer`, `configureScrollViewForGlass`, `configureTableViewForGlass`) instead of inline NSVisualEffectView setup
- **Selection Colors**: Glass-aware selection colors via `selectedBackgroundColorForGlass()`

### Fixed

- **Drag & Drop from SimPlaylist**: Updated pasteboard decoder to handle new NSDictionary format (sourcePlaylist, indices, paths)
- **Header Appearance**: Header now renders with correct dark appearance matching SimPlaylist

## [1.0.0] - 2025-12-29

Initial release of Queue Manager for foobar2000 macOS.

### Features

- **Queue Display**: Visual table view showing all items in the playback queue
  - Queue position (#), Artist - Title, and Duration columns
  - Live updates when queue changes

- **Queue Management**
  - Double-click to play item from queue
  - Delete/Backspace key to remove selected items
  - Multi-selection support

- **Drag & Drop**
  - Internal reordering within the queue
  - Drop from SimPlaylist to add tracks to queue

- **Visual Design**
  - Matches SimPlaylist appearance (row height, colors, selection style)
  - Glass/vibrancy background option (transparent mode)
  - Custom header styling
  - Status bar showing item count

- **Preferences**
  - Transparent background toggle (Preferences > Display > Queue Manager)

### Technical

- Uses `NSVisualEffectView` for glass effect
- Persists settings via `fb2k::configStore`
- Thread-safe callback handling with debounce support
