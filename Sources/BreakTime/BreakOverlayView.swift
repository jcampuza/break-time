import SwiftUI
import BreakTimeCore

struct BreakOverlayView: View {
    @Bindable var engine: BreakTimeEngine

    var body: some View {
        let snapshot = engine.snapshot
        let config = engine.config

        ZStack {
            Rectangle()
                .fill(.black.opacity(0.55))
                .ignoresSafeArea()

            VStack(spacing: 20) {
                if snapshot.state == .inMini || snapshot.state == .inWork {
                    let isWorkBreak = snapshot.state == .inWork
                    let duration = isWorkBreak ? config.work.durationSeconds : config.mini.durationSeconds
                    let elapsed = isWorkBreak ? snapshot.timings.workTaking : snapshot.timings.miniTaking
                    let remaining = max(duration - elapsed, 0)

                    Text(isWorkBreak ? "Work Break" : "Micro Break")
                        .font(.system(size: 40, weight: .bold))

                    Text("Relax your hands and look away from the screen.")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    Text(formatSeconds(remaining))
                        .font(.system(size: 64, weight: .semibold, design: .rounded))
                        .monospacedDigit()

                    ProgressView(value: elapsed, total: duration)
                        .frame(maxWidth: 320)

                    HStack(spacing: 12) {
                        if isWorkBreak {
                            Button("Postpone") {
                                engine.postponeWorkBreak()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        Button("Skip") {
                            if isWorkBreak {
                                engine.skipWorkBreak()
                            } else {
                                engine.skipMiniBreak()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    Text("Break Complete")
                        .font(.system(size: 40, weight: .bold))
                    Text("You can get back to work when the overlay closes.")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(40)
            .frame(maxWidth: 520)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
        }
    }
}
