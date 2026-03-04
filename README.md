# Claude Status Bar

> Never miss a Claude outage.

macOS menu bar app that monitors Claude's service status and sends real-time notifications when incidents occur.

## Features

- **Menu bar status indicator** — Color-coded circle icon shows overall system health at a glance
  - Green: All systems operational
  - Yellow: Minor issues
  - Orange: Major outage
  - Red: Critical outage
  - Gray: Connection error
- **Component status** — View individual status for claude.ai, Claude API, Claude Code, platform.claude.com, and Claude for Government
- **Incident details** — Active incidents displayed with impact level, current status, and latest update message
- **Desktop notifications** — Alerts when Claude goes down and when it recovers
- **Launch at Login** — Optional auto-start on login
- **Open Status Page** — Quick link to [status.claude.com](https://status.claude.com)

## Requirements

- macOS 14.0 (Sonoma) or later

## Installation

### Build from source

```bash
git clone https://github.com/morinpic/Claude-Status-Bar.git
cd Claude-Status-Bar
xcodebuild -scheme ClaudeStatusBar -configuration Release build
```

The built app will be in `DerivedData/ClaudeStatusBar-*/Build/Products/Release/ClaudeStatusBar.app`.

### From Xcode

1. Open `ClaudeStatusBar.xcodeproj` in Xcode
2. Select the `ClaudeStatusBar` scheme
3. Build and run (Cmd+R)

## Usage

1. Launch the app — a colored circle appears in the menu bar
2. Click the icon to see detailed status for all Claude services
3. When an incident occurs, you'll receive a macOS notification
4. Enable "Launch at Login" in the popover to start automatically

## How It Works

The app polls the [Statuspage API](https://status.claude.com/api/v2/summary.json) every 60 seconds. On failure, it retries with exponential backoff (60s → 120s → 240s, max 300s).

## License

[MIT](LICENSE)
