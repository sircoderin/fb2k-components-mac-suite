# foo_jl_albumviewvanced

> Part of [foobar2000 macOS Components Suite](../../README.md)

Album-first library browser with cover thumbnails and quick queue/play actions.

## Usage

Add **AlbumViewVanced** to your layout (Layout Editor).

Accepted layout names:
- `AlbumViewVanced` (recommended)
- `albumviewvanced`
- `album_view_vanced`

## Shortcuts & Interactions

- **Enter** — play selected album/track
- **Q** — add selected album/track to playback queue
- **Space** — play/pause
- **Esc** — collapse expanded album
- **Arrow keys** — navigate albums/tracks
- **Double-click** — play clicked album/track
- **Right-click** — open context menu
- **Drag** album/track — drop into SimPlaylist, Queue Manager, PlayVanced, or Finder

## Important Behavior

- Selecting an album and pressing **Enter** plays that album immediately.
- **Q** queues without switching view context.
- Search is live with a short debounce; **Enter** applies immediately and **Esc** in the search field clears it.
- If queue is empty and playback is stopped, queue actions can auto-start playback.

## Changelog

- [CHANGELOG.md](CHANGELOG.md)
