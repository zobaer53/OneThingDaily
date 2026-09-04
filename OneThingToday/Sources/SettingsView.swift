import SwiftUI
import OneThingTodayDomain

struct SettingsView: View {
    @State var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("Daily times") {
                DatePicker("Morning check-in", selection: $viewModel.morningTime, displayedComponents: .hourAndMinute)
                DatePicker("Evening reflection", selection: $viewModel.eveningTime, displayedComponents: .hourAndMinute)
            }

            Section {
                Button(viewModel.isScheduled ? "Reschedule" : "Enable Daily Reminders") {
                    Task { await viewModel.reschedule() }
                }
            }

            Section("Permissions") {
                Label(
                    viewModel.isScheduled ? "Alarms are scheduled" : "Alarms aren't scheduled yet",
                    systemImage: viewModel.isScheduled ? "checkmark.circle.fill" : "exclamationmark.circle"
                )
                .foregroundStyle(viewModel.isScheduled ? .green : .secondary)
                .accessibilityElement(children: .combine)
            }

            if let plan = viewModel.plan {
                Section("What gets scheduled") {
                    ForEach(Array(plan.checkpoints.enumerated()), id: \.offset) { _, checkpoint in
                        HStack {
                            Text(label(for: checkpoint.kind))
                            Spacer()
                            Text(timeString(checkpoint.time))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }

            Section("Privacy") {
                Text("One Thing Today has no account, no analytics, and no server. Your task, reflections, and schedule are stored only on this device. The on-device AI that sharpens tasks and writes your weekly digest runs entirely on your iPhone — nothing you type is ever sent anywhere.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let error = viewModel.errorMessage {
                Section("Error") {
                    Text(error).foregroundStyle(.red)
                }
            }

            Section {
                Button("Refresh Debug Trace") {
                    Task { await viewModel.refreshDebugTrace() }
                }
            } footer: {
                Text("Reads the shared log without touching alarms — use this after doing something on the Today tab (starting/relaying/ending a Live Activity) to see what happened.")
            }

            if !viewModel.debugTrace.isEmpty {
                Section("Debug trace") {
                    ForEach(Array(viewModel.debugTrace.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
            }

            #if DEBUG
            Section {
                Stepper(
                    "Compressed clock: 1h ≈ \(compressedSecondsPerHour, specifier: "%.0f")s",
                    value: $viewModel.debugCompressionFactor,
                    in: 1...3600,
                    step: 60
                )
            } header: {
                Text("Debug only")
            } footer: {
                Text("Shrinks the 8h relay window and the Live Activity stale date so the relay/stale/dismiss behavior can be exercised in a short manual run. Never compiled into release builds, and never changes the real, OS-enforced 8h/12h Live Activity limits.")
            }
            #endif
        }
        .navigationTitle("Settings")
    }

    #if DEBUG
    private var compressedSecondsPerHour: Double {
        3600 / viewModel.debugCompressionFactor
    }
    #endif

    private func label(for kind: AlarmCheckpoint.Kind) -> String {
        switch kind {
        case .morning: return "Morning check-in"
        case .relay: return "Midday nudge (relay)"
        case .evening: return "Evening reflection"
        }
    }

    private func timeString(_ components: DateComponents) -> String {
        String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }
}
