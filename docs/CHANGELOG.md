# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Polling interval selection in Settings (15s / 30s / 60s / 2min / 5min, default 60s)

## [2.2.0] - 2026-03-29

### Added

- New icon design: "Vibe" — emoji-based status indicator (😊😟😰💀🤔)
- Icon Design selection in Settings with card-style UI showing all 5 states per design

### Changed

- Default menu bar icon to SF Symbols shape-based design (Status Icons): `checkmark.circle`, `info.circle`, `exclamationmark.circle`, `xmark.circle`, `questionmark.circle`
- Classic icon design now uses flat colors via `NSColor.system*` for consistent appearance
- Unify all status colors across the app to `Color(nsColor: .system*)`
- Move Reset button to bottom-right of Settings as a bordered button

### Removed

- Custom SVG icon assets (Shield, Arc, Ring, Buddy — 4 designs × 5 states)

## [2.1.0] - 2026-03-29

### Added

- Japanese localization — all UI text, notifications, and settings are now available in Japanese
- In-app language switcher (System Default / English / Japanese) in Settings
- Notification messages respect the selected app language

## [2.0.0] - 2026-03-28

### Changed

- Raise minimum deployment target from macOS 14 to macOS 26 (Tahoe)
- Apply Liquid Glass design to status badge, incident cards, and debug menu buttons
- Use template rendering for custom menu bar icons (transparent menu bar support)
- Sign release builds with Developer ID certificate and notarize with Apple (Gatekeeper compatible)

## [1.2.0] - 2026-03-28

### Added

- Notification test controls in debug menu (direct send + transition simulation)
- Per-component notification settings — choose which components trigger notifications
- Component-level status change notifications (individual component outage/recovery)

### Changed

- Move Icon Design, Notification Settings, and Launch at Login to dedicated Settings window
- Add gear icon button in popover footer to open Settings

## [1.1.1] - 2026-03-27

### Added

- Debug menu for state simulation in DEBUG builds (status, incidents, components, errors, loading)

### Fixed

- Fix header status showing "All Systems Operational" when active incidents exist

## [1.1.0] - 2026-03-05

### Added

- Icon design selection setting — choose between 5 menu bar icon designs (Default, Shield + Pulse, Abstract C, Connection Ring, Claude-kun)
- Custom SVG icons registered in asset catalog (4 designs x 5 states)
- GitHub repository link in popover footer
- Bug report link (GitHub Issues) in popover footer
- Release automation with GitHub Actions (tag push triggers build, GitHub Release, and Homebrew Cask update)

## [1.0.0] - 2026-03-04

### Added

- Menu bar status indicator with color-coded icons (green/yellow/orange/red)
- Component-level status display (claude.ai, Claude API, Claude Code, platform.claude.com, Claude for Government)
- Incident detail cards with impact level, status, and latest update message
- Desktop notifications on status changes (outage start and recovery)
- Launch at Login support
- Quick link to status.claude.com
- Error handling with graceful UI for network failures
- Homebrew Cask distribution via `brew tap morinpic/tap`

[2.2.0]: https://github.com/morinpic/Claude-Status-Bar/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/morinpic/Claude-Status-Bar/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/morinpic/Claude-Status-Bar/compare/v1.2.0...v2.0.0
[1.2.0]: https://github.com/morinpic/Claude-Status-Bar/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/morinpic/Claude-Status-Bar/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/morinpic/Claude-Status-Bar/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/morinpic/Claude-Status-Bar/releases/tag/v1.0.0
