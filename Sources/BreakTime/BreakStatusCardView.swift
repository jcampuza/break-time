import SwiftUI
import BreakTimeCore

struct BreakStatusCardView: View {
    let breakType: BreakType
    @Bindable var engine: BreakTimeEngine

    var body: some View {
        let config = engine.config
        let snapshot = engine.snapshot
        let isActive = (breakType == .mini && snapshot.state == .inMini) ||
            (breakType == .work && snapshot.state == .inWork)
        let elapsed = breakType == .mini ? snapshot.timings.miniElapsed : snapshot.timings.workElapsed
        let duration = breakType == .mini ? config.mini.durationSeconds : config.work.durationSeconds
        let intervalMax = breakType == .mini ? config.mini.intervalSeconds : config.work.intervalSeconds
        let pending = max(intervalMax - elapsed, 0)
        let label = breakType == .mini ? "Micro Pause" : "Work Break"

        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text(formatSeconds(pending))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                    Spacer()
                    Text(isActive ? "Active" : "Idle")
                        .font(.caption)
                        .foregroundStyle(isActive ? .orange : .secondary)
                }
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Time Until Next")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formatSeconds(duration))
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("Duration")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                ProgressView(value: elapsed, total: intervalMax)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        } label: {
            Text(label)
                .font(.headline)
        }
    }
}
