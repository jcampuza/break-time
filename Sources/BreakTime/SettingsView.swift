import SwiftUI
import BreakTimeCore

struct SettingsView: View {
    @Bindable var engine: BreakTimeEngine

    @State private var miniInterval: Double
    @State private var miniDuration: Double
    @State private var workInterval: Double
    @State private var workDuration: Double
    @State private var workPostpone: Double

    init(engine: BreakTimeEngine) {
        self.engine = engine
        _miniInterval = State(initialValue: engine.config.mini.intervalSeconds)
        _miniDuration = State(initialValue: engine.config.mini.durationSeconds)
        _workInterval = State(initialValue: engine.config.work.intervalSeconds)
        _workDuration = State(initialValue: engine.config.work.durationSeconds)
        _workPostpone = State(initialValue: engine.config.work.postponeSeconds)
    }

    var body: some View {
        Form {
            Section("Micro Pause") {
                TimingField(label: "Interval (sec)", value: $miniInterval, minimum: 30)
                TimingField(label: "Duration (sec)", value: $miniDuration, minimum: 3)
            }

            Section("Work Break") {
                TimingField(label: "Interval (sec)", value: $workInterval, minimum: 60)
                TimingField(label: "Duration (sec)", value: $workDuration, minimum: 60)
                TimingField(label: "Postpone Amount (sec)", value: $workPostpone, minimum: 60)
            }

            HStack(spacing: 12) {
                Button("Apply Config") {
                    let mini = BreakConfig(intervalSeconds: miniInterval, durationSeconds: miniDuration)
                    let work = WorkBreakConfig(
                        intervalSeconds: workInterval,
                        durationSeconds: workDuration,
                        postponeSeconds: workPostpone
                    )
                    engine.applyConfig(mini: mini, work: work)
                }
                .buttonStyle(.borderedProminent)

                Button("Reset Defaults") {
                    engine.resetConfig()
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .formStyle(.grouped)
        .frame(maxWidth: 520, alignment: .leading)
        .padding(24)
        .onChange(of: engine.config) { _, newValue in
            miniInterval = newValue.mini.intervalSeconds
            miniDuration = newValue.mini.durationSeconds
            workInterval = newValue.work.intervalSeconds
            workDuration = newValue.work.durationSeconds
            workPostpone = newValue.work.postponeSeconds
        }
    }
}

struct TimingField: View {
    let label: String
    @Binding var value: Double
    let minimum: Double

    var body: some View {
        LabeledContent(label) {
            HStack(spacing: 8) {
                TextField("", value: $value, format: .number)
                    .frame(width: 90)
                    .multilineTextAlignment(.trailing)
                Stepper("", value: $value, in: minimum...36000, step: 1)
                    .labelsHidden()
            }
            .frame(maxWidth: 180, alignment: .leading)
        }
    }
}
