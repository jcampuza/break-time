# BreakTime

BreakTime is a macOS menu bar app that helps schedule regular breaks to prevent RSI.
It pairs a SwiftUI app with a focused core state machine in `BreakTimeCore`.

## Requirements

- macOS 15+
- Swift 6.1 / Xcode 16+

## Development

- Build and launch the app: `./Scripts/compile_and_run.sh`
- Run tests only: `swift test`
- Build without launching: `swift build`

## Project Layout

- `Sources/BreakTime`: SwiftUI app and window/overlay orchestration
- `Sources/BreakTimeCore`: Core timing + reducer logic
- `Tests/BreakTimeCoreTests`: XCTest coverage for the core
