import Foundation

func formatSeconds(_ seconds: Double) -> String {
    let clamped = max(0, Int(seconds.rounded(.down)))
    let hours = clamped / 3600
    let minutes = (clamped % 3600) / 60
    let secs = clamped % 60

    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, secs)
    }
    return String(format: "%d:%02d", minutes, secs)
}
