# HabitFlow

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2015.0%2B-blue.svg" alt="Platform macOS 15+">
  <img src="https://img.shields.io/badge/Swift-6.0-orange.svg" alt="Swift 6.0">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License MIT">
  <img src="https://img.shields.io/badge/Offline-100%25-brightgreen.svg" alt="Offline 100%">
</p>

**HabitFlow** is a native, lightweight, and privacy-first macOS habit tracker featuring interactive Desktop widgets, GitHub-style contribution heatmaps, local-first SwiftData storage, Apple Charts analytics, and offline statistical insights. 

Designed strictly to respect Apple’s Human Interface Guidelines (HIG), HabitFlow combines sleek minimalist aesthetics with fast, keyboard-driven navigation.

---

## Key Features

- **Interactive Desktop Widgets**: Complete habits directly from your macOS Desktop or Notification Center without opening the main app (leveraging WidgetKit + AppIntents).
- **GitHub-style Heatmaps**: Visualize consistency with month/year grid views, color intensity based on completion rates, smooth scale animations, and hover tooltips.
- **Offline Analytical Insights**: Intelligent patterns computed locally (e.g., "Your best productivity day is Tuesday", "Fitness completion drops after 8 PM") with zero network requests.
- **Local SwiftData Container**: Fast, reliable, local-only SQLite databases utilizing SwiftData schema with automated weekly snapshots.
- **Custom Schedules**: Flexibility to track Daily, Weekly target goals (e.g. 3 days/week), Alternate Days, or Custom Weekday checklists (e.g. Mon, Wed, Fri).
- **Import/Export Suite**: Instant manual/auto backups, CSV spreadsheet exports/imports, and vector-drawn PDF reports ready for print.
- **Aesthetic Customization**: Personalize layout densities (Compact, Comfortable, Spacious), grid shapes (Rounded, Square, Circles), and interactive widget themes (Minimal, Glass, Monochrome, GitHub Style, Apple Notes Style).
- **Universal Accessibility**: Optimized with semantic VoiceOver announcements, high-contrast, dynamic type sizing, and full keyboard navigation focus styles.

---

## Keyboard Shortcuts

- `⌘ N` - Create Habit
- `⌘ F` - Search Habits
- `⌘ E` - Export Database
- `⌘ ,` - Open Preferences
- `Space` - Toggle Completion of Selected Habit

---

## Technical Architecture

HabitFlow is structured using clean, decoupled MVVM architecture using Swift 6 concurrency patterns:

```
HabitFlow/
├── App/            # HabitFlowApp entry & database containers
├── Models/         # SwiftData entities (Habit, HabitLog, CustomCategory)
├── ViewModels/     # Observable logic (DashboardViewModel, HabitListViewModel)
├── Views/          # UI layouts (DashboardView, MainSidebarView, PreferenceView)
├── Widgets/        # WidgetKit extensions & ToggleHabitIntent
├── Components/     # Custom widgets (StatCard, ContributionGridView)
├── Services/       # Notifications, BackupService, local InsightEngine
├── Export/         # CSV formatters and printable PDF graphics context drawer
├── Import/         # CSV parser and database merger
├── Resources/      # Plists, Preview Assets, and asset catalog
├── Tests/          # Unit tests (model validation, streak metrics tests)
└── Documentation/  # Repo guides
```

---

## Getting Started & Building

HabitFlow offers both a native macOS graphical application (requires Xcode) and a lightweight standalone Command Line Interface (CLI) version which compiles instantly without Xcode.

### Option A: Running the Terminal (CLI) Edition (No Xcode Needed)

This is the lightweight version that runs directly in your terminal, using zero extra disk space and requiring only standard command line tools.

1. **Build the CLI**:
   ```bash
   swiftc habitflow-cli.swift -o habitflow-cli
   ```
2. **Run it**:
   ```bash
   ./habitflow-cli
   ```

---

### Option B: Running the Native macOS GUI Application (Requires Xcode)

HabitFlow uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to manage project configurations cleanly.

#### Prerequisites

- macOS 15.0 or later
- Xcode 16.0 or later
- Homebrew (recommended)

#### Build Instructions

1. **Install XcodeGen**:
   ```bash
   brew install xcodegen
   ```
2. **Generate the Xcode Project**:
   Run this command in the project root folder. It compiles targets for the macOS application, Widget Extension, and Unit Tests:
   ```bash
   xcodegen generate
   ```
3. **Open and Run**:
   Open the generated project bundle and run the `HabitFlow` target in Xcode:
   ```bash
   open HabitFlow.xcodeproj
   ```
4. **Running Unit Tests**:
   Press `⌘ U` in Xcode.

---

## Author & Maintainer

Developed and maintained by **Rajnish Singh**.

## License

HabitFlow is open source and available under the [MIT License](LICENSE).
