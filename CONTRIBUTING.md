# Contributing to HabitFlow

Thank you for your interest in contributing to HabitFlow! We welcome contributions to help make this the best privacy-first macOS habit tracker.

## Code of Conduct

By participating in this project, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md).

## Development Setup

HabitFlow uses **XcodeGen** to manage its Xcode project files. This keeps the repository clean and avoids merge conflicts on the `.xcodeproj` directory.

### Prerequisites

- macOS 15.0 or later
- Xcode 16.0 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (can be installed via Homebrew)

### Setup Steps

1. Install XcodeGen:
   ```bash
   brew install xcodegen
   ```
2. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/HabitFlow.git
   cd HabitFlow
   ```
3. Generate the Xcode project:
   ```bash
   xcodegen generate
   ```
4. Open the generated `HabitFlow.xcodeproj` in Xcode:
   ```bash
   open HabitFlow.xcodeproj
   ```

## Folder Structure

Please place your modifications in the appropriate subdirectories:

- `HabitFlow/App/`: Main entry, App container, database settings.
- `HabitFlow/Models/`: SwiftData entity schemas.
- `HabitFlow/ViewModels/`: Logic and statistics calculator.
- `HabitFlow/Views/`: SwiftUI views and dashboards.
- `HabitFlow/Widgets/`: WidgetKit timeline providers, interactive layouts, and AppIntents.
- `HabitFlow/Components/`: General reusable UI panels and cards.
- `HabitFlow/Services/`: Local-first backups, notifications, and statistics insight engines.
- `HabitFlow/Export/` & `Import/`: CSV, JSON, and PDF handling.
- `Tests/`: Unit and logic validations.

## Testing Guidelines

Before opening a pull request, please ensure that:
- The project compiles successfully without warnings.
- All unit tests pass. You can run tests using `⌘U` in Xcode or run:
  ```bash
  swift test
  ```
- Coverage for new business logic should remain above 80%.

## Submitting Pull Requests

1. Fork the repository and create a branch from `main`:
   ```bash
   git checkout -b feature/your-awesome-feature
   ```
2. Write clean code adhering to Swift 6 concurrency guidelines.
3. Commit your changes:
   ```bash
   git commit -m "Add custom feature description"
   ```
4. Push to your fork and submit a Pull Request to our `main` branch.
