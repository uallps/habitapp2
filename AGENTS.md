# Repository Guidelines

## Project Structure & Module Organization
`HabitApp/` contains the SwiftUI application code. Key areas include `HabitApp/Application` for app entry and configuration, `HabitApp/Core` for shared models, view models, and base views, and `HabitApp/Features` for feature-specific folders (for example, `Statistics`, `DailyNotes`, `Streaks`). Cross-cutting concerns live under `HabitApp/Infraestructure`, including plugin wiring and persistence adapters. Assets and app icons are in `HabitApp/Assets.xcassets`. Tests live in `HabitAppTests/` and use `@testable import HabitApp`.

## Build, Test, and Development Commands
- `open HabitApp.xcodeproj` opens the project in Xcode for running on a simulator or device.
- `xcodebuild -project HabitApp.xcodeproj -scheme HabitApp -destination 'platform=iOS Simulator,name=iPhone 15' build` builds the app from the command line.
- `xcodebuild -project HabitApp.xcodeproj -scheme HabitApp -destination 'platform=iOS Simulator,name=iPhone 15' test` runs the XCTest suite.
- `xcodebuild -list -project HabitApp.xcodeproj` shows available schemes and targets.

## Coding Style & Naming Conventions
Use 4-space indentation and follow Swift API Design Guidelines. Type names are PascalCase (`HabitStatisticsViewModel`), while properties and functions are lowerCamelCase (`isCompletedToday`). Files generally match their primary type name (for example, `HabitListViewModel.swift`). No formatter or linter is configured, so keep formatting consistent with nearby code.

## Testing Guidelines
Tests are written with XCTest in `HabitAppTests/`. Use `test...` prefixes for methods and keep tests focused on view models, models, and persistence behaviors. There is no explicit coverage target, but new behavior should include tests when feasible. Run tests via Xcode or the `xcodebuild ... test` command.

## Commit & Pull Request Guidelines
Git history follows Conventional Commits (for example, `feat:`, `fix:`). Keep commits small and scoped to one change. Pull requests should include a brief summary, testing evidence (command or Xcode run), and screenshots for UI changes. Link related issues when applicable.
