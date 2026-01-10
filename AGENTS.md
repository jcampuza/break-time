# BreakTime Repository Guidelines

## Project Structure & Modules

- `Sources/BreakTime`: SwiftUI menu bar app, window orchestration, permissions, process monitoring, overlays.
- `Sources/BreakTimeCore`: Core AntiRSI state machine, config types, events, and reducers.
- `Tests/BreakTimeCoreTests`: XCTest coverage for core timing logic and state transitions.
- `Scripts`: Dev loop helpers (`compile_and_run.sh`, `package_app.sh`).
- `Resources`: App bundle assets and Info.plist templates (generated during packaging).

## Current Status

- Core break scheduling, overlays, and menu bar flows are in place; focus on refinement.
- Prioritize bug fixes, polish, accessibility, and reliability over new features.
- Coordinate any large refactors or new dependencies first.

## Build, Test, Run

- Dev loop: `./Scripts/compile_and_run.sh` kills old instances, runs `swift build` + `swift test`, packages, relaunches `BreakTime.app`, and confirms it stays running.
- Quick build/test: `swift build` (debug) or `swift build -c release`; `swift test` for XCTest.
- Package locally: `./Scripts/package_app.sh` to refresh `BreakTime.app`, then restart with `pkill -x BreakTime || pkill -f BreakTime.app || true; open -n ./BreakTime.app`.

## Coding Style & Naming

- Favor small, typed structs/enums and clear naming.
- Prefer modern SwiftUI + Observation macros: use `@Observable` models with `@State` ownership and `@Bindable` in views; avoid `ObservableObject`, `@ObservedObject`, and `@StateObject`.
- Keep timing constants, IPC/notifications, and state transitions documented near their definitions.

## Testing Guidelines

- Add or extend XCTest cases under `Tests/BreakTimeCoreTests/*Tests.swift` with focused, descriptive test names.
- Always run swift test (or ./Scripts/compile_and_run.sh) before handoff; add fixtures for new parsing/formatting scenarios.

## Agent Notes

- Use SwiftPM; avoid adding dependencies or tooling without confirmation.
- Validate behavior against the freshly built bundle; restart via the `pkill` + `open` command above to avoid stale binaries.
- Prefer macOS 15+ APIs over legacy/deprecated counterparts.
- If you edited any code affecting the app, run scripts/compile_and_run.sh before handoff; it kills old instances, builds, tests, packages, relaunches, and verifies the app stays running.
- Per user request: after every edit (code or docs), rebuild and restart using ./Scripts/compile_and_run.sh so the running app reflects the latest changes.
