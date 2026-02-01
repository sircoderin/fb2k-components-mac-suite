# Changelog

All notable changes to foo_jl_scrobble (Last.fm Scrobbler) will be documented in this file.

## [1.2.0] - 2026-02-01

### Added
- Artist image scraping from Last.fm website (API deprecated artist images in 2019)
- Track images via album artwork lookup using track.getInfo API
- Widget background customization in preferences (color picker)
- Glass background effect option (NSVisualEffectView)
- Reload button in widget header for manual refresh
- Rank display in tooltip for bubble view (#1, #2, etc.)

### Changed
- Footer is now sticky at bottom of widget
- Bubble view is vertically centered between header and footer
- Removed rank badges from bubble view (cleaner look, rank shown in tooltip)
- Scrobbled today count updates after each successful scrobble
- Error handling improved: partial failures show in footer instead of full-screen error

### Fixed
- Animation duplicate issue where items appeared both animated and at final positions
- Layout transitions now properly suppress drawing during animation

## [1.1.0] - 2025-12-30

### Added
- Stats widget for foobar2000 layout system
- Top albums grid display (weekly/monthly/all time)
- Top artists and tracks navigation (UI ready, API pending)
- Profile image and username display
- Scrobbled today counter
- Queue status indicator
- Album artwork loading with caching
- Click albums to open on Last.fm
- Click profile link to open user library on Last.fm
- Context menu for period selection and refresh

### Fixed
- Widget properly supports container column resizing

## [1.0.0] - 2025-12-26

### Added
- Initial release
- Last.fm authentication via web browser
- Automatic scrobbling after 50% or 4 minutes played
- Now Playing notifications
- Offline queue with automatic retry
- Preferences page for configuration
