# WindDown

A minimal macOS menu bar app that blocks work apps and websites after hours to help you maintain healthy work-life boundaries.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)

## Download

**[Download WindDown.dmg](https://github.com/ghosharnab00/WindDown/releases/download/v1.0.0/WindDown.dmg)**

## Installation

1. Download `WindDown.dmg`
2. Double-click to open the DMG
3. Drag `WindDown.app` to the `Applications` folder
4. Open WindDown from Applications

### First Launch (Important)

Since the app isn't notarized by Apple, macOS will block it initially:

1. **Right-click** (or Control-click) on `WindDown.app`
2. Select **Open** from the menu
3. Click **Open** in the dialog that appears

You only need to do this once. After that, the app will open normally.

### Grant Permissions

WindDown needs these permissions to work:

- **Notifications**: To alert you when blocking starts
- **Accessibility** (optional): For enhanced app monitoring

## Features

- **App Blocking** - Automatically terminates work apps (Slack, Teams, VS Code, etc.) during personal time
- **Website Blocking** - Blocks work websites by modifying `/etc/hosts` (Gmail, GitHub, Notion, etc.)
- **Scheduled Blocking** - Set custom start/end times with 15-minute precision
- **Brain Dump** - Write down lingering work thoughts before disconnecting, stored locally by date
- **Manual Override** - Lock/unlock anytime from the menu bar
- **System Notifications** - Get notified when blocking starts and when blocked apps are launched

## Screenshots

The app lives in your menu bar with a moon icon. Click to access:

- **Status** - See current blocking state and toggle manually
- **Settings** - Configure schedule, manage blocked apps/websites
- **Wind Down** - Brain dump and view history

## Installation

1. Clone the repository
2. Open `WindDown.xcodeproj` in Xcode
3. Build and run (⌘R)

## How It Works

### App Blocking
Monitors `NSWorkspace` for app launches. When a blocked app starts during blocking hours, it's terminated and you receive a notification.

### Website Blocking
Adds entries to `/etc/hosts` to redirect blocked domains to `0.0.0.0`. Requires admin password when activating/deactivating.

### Brain Dump
Before blocking starts, write down any work thoughts on your mind. Entries are saved locally and can be viewed in the History tab.

## Default Blocked Apps

- Slack, Microsoft Teams, Zoom
- VS Code, Xcode
- Notion, Figma

## Default Blocked Websites

- Gmail, Google Calendar, Google Drive
- GitHub, GitLab
- Slack, Notion, Linear
- LinkedIn, Twitter/X

## Adding Custom Apps/Websites

1. Go to **Settings** tab
2. Select **Apps** or **Websites**
3. Click **Add App** or **Add Website**
4. For apps, you'll need the Bundle ID (found in the app's Info.plist)

## Requirements

- macOS 13.0 or later
- Admin password (for website blocking via /etc/hosts)

## Privacy

- All data stored locally in `~/Library/Application Support/WindDown/`
- No analytics or external connections
- No data leaves your machine

## License

MIT
