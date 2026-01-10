import SwiftUI
import BreakTimeCore

struct DashboardView: View {
    @Bindable var engine: BreakTimeEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("BreakTime")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Micro pauses and work breaks to reduce RSI.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if engine.isPaused {
                if engine.processes.isEmpty {
                    Text("Timers paused")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                } else {
                    Text("Timers paused because of active processes: \(engine.processes.joined(separator: ", "))")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
            }

            HStack(spacing: 16) {
                BreakStatusCardView(breakType: .mini, engine: engine)
                BreakStatusCardView(breakType: .work, engine: engine)
            }

            BreakActionsView(engine: engine)

            Spacer()
        }
        .padding(24)
    }
}

struct BreakActionsView: View {
    @Bindable var engine: BreakTimeEngine

    var body: some View {
        HStack(spacing: 12) {
            Button("Start Work Break") {
                engine.startWorkBreak()
            }
            .buttonStyle(.borderedProminent)

            Button("Micro Pause") {
                engine.startMiniBreak()
            }
            .buttonStyle(.bordered)

            Button("Postpone Work Break") {
                engine.postponeWorkBreak()
            }
            .buttonStyle(.bordered)

            Button(engine.isPaused ? "Resume Timers" : "Pause Timers") {
                engine.setUserPaused(!engine.isPaused)
            }
            .buttonStyle(.bordered)

            Button("Reset Timers") {
                engine.resetTimings()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
