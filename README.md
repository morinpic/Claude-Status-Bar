# Claude Status Bar

[![CI](https://github.com/morinpic/Claude-Status-Bar/actions/workflows/ci.yml/badge.svg)](https://github.com/morinpic/Claude-Status-Bar/actions/workflows/ci.yml)
[![GitHub Release](https://img.shields.io/github/v/release/morinpic/Claude-Status-Bar)](https://github.com/morinpic/Claude-Status-Bar/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-26.0%2B-blue)](https://github.com/morinpic/Claude-Status-Bar)

> Never miss a Claude outage.

macOS menu bar app that monitors Claude's service status and sends real-time notifications when incidents occur.

## Features

- **Menu bar status indicator** — Icon changes shape based on system health at a glance
  - ✓ checkmark.circle: All systems operational
  - ℹ info.circle: Minor issues
  - ! exclamationmark.circle: Major outage
  - ✕ xmark.circle: Critical outage
  - ? questionmark.circle: Connection error
- **Component status** — View individual status for claude.ai, Claude API, Claude Code, platform.claude.com, and Claude for Government
- **Incident details** — Active incidents displayed with impact level, current status, and latest update message
- **Desktop notifications** — Alerts when Claude goes down and when it recovers
- **Icon design selection** — Choose from 3 menu bar icon styles: Status Icons (shape-based), Classic (color-coded circle), and Vibe (emoji)
- **Polling interval** — Configurable polling interval (15s / 30s / 60s / 2min / 5min)
- **Language support** — English and Japanese, switchable in Settings (or follows system language)
- **Launch at Login** — Optional auto-start on login
- **Quick links** — Open [status.claude.com](https://status.claude.com), GitHub repository, or file a bug report directly from the popover

## Requirements

- macOS 26.0 (Tahoe) or later

## Installation

### Homebrew (Recommended)

```bash
brew tap morinpic/tap && brew install --cask claude-status-bar
```

### Manual Download

Download the latest `ClaudeStatusBar-x.x.x.zip` from [Releases](https://github.com/morinpic/Claude-Status-Bar/releases/latest), unzip, and move `ClaudeStatusBar.app` to `/Applications`.

### Build from Source

```bash
git clone https://github.com/morinpic/Claude-Status-Bar.git
cd Claude-Status-Bar
xcodebuild -scheme ClaudeStatusBar -configuration Release build
```

The built app will be in `DerivedData/ClaudeStatusBar-*/Build/Products/Release/ClaudeStatusBar.app`.

## Usage

1. Launch the app — a status icon appears in the menu bar
2. Click the icon to see detailed status for all Claude services
3. When an incident occurs, you'll receive a macOS notification
4. Enable "Launch at Login" in the popover to start automatically

## How It Works

The app polls the [Statuspage API](https://status.claude.com/api/v2/summary.json) at a configurable interval (default: 60 seconds). On failure, it retries with exponential backoff (up to 300s).

## License

[MIT](LICENSE)
