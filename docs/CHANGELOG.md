# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Debug menu for state simulation in DEBUG builds (status, incidents, components, errors, loading)

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

[1.1.0]: https://github.com/morinpic/Claude-Status-Bar/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/morinpic/Claude-Status-Bar/releases/tag/v1.0.0
