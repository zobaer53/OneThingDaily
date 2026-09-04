import SwiftUI
import OneThingTodayDomain

struct TodayView: View {
    @State var viewModel: TodayViewModel
    @FocusState private var draftFieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let session = viewModel.session {
                    phaseBadge(for: session)
                }

                if viewModel.hasActiveTask, let session = viewModel.session {
                    taskCard(session)
                } else if viewModel.session?.isDone == true {
                    doneCard
                } else {
                    taskEntry
                }

                if viewModel.canResumeLiveActivity {
                    resumeCard
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .accessibilityLabel("Error: \(error)")
                }

                Spacer(minLength: 12)

                Text("Force-quit and reopen any time — today's task is always saved.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(20)
        }
        .navigationTitle("Today")
        .task { await viewModel.load() }
    }

    private func phaseBadge(for session: FocusDaySession) -> some View {
        HStack(spacing: 6) {
            Image(systemName: phaseIcon(session.phase))
            Text(phaseLabel(session.phase))
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
    }

    private var taskEntry: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What's the one thing today?")
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)

            TextField("e.g. Finish the quarterly report", text: $viewModel.draftText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .focused($draftFieldFocused)
                .submitLabel(.done)
                .onSubmit { Task { await viewModel.start() } }

            Button {
                Task { await viewModel.start() }
            } label: {
                if viewModel.isBusy {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text("Set Today's Focus").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isBusy)
        }
    }

    private func taskCard(_ session: FocusDaySession) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                if session.isSharpened {
                    Label("Sharpened", systemImage: "sparkles")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tint)
                }
                Text(session.taskText)
                    .font(.title2.weight(.semibold))
            }
            .accessibilityElement(children: .combine)

            HStack(spacing: 12) {
                Button {
                    Task { await viewModel.complete() }
                } label: {
                    Label("Mark Done", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                if viewModel.isAISharpenAvailable && !session.isSharpened {
                    Button {
                        Task { await viewModel.sharpen() }
                    } label: {
                        Label("Sharpen", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .disabled(viewModel.isBusy)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var doneCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Done for today", systemImage: "checkmark.circle.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.green)
            if let text = viewModel.session?.taskText, !text.isEmpty {
                Text(text)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var resumeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Not on your Lock Screen right now")
                .font(.subheadline.weight(.medium))
            Button {
                Task { await viewModel.resumeLiveActivity() }
            } label: {
                Label("Resume on Lock Screen", systemImage: "lock.rectangle.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isBusy)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
    }

    private func phaseIcon(_ phase: DayPhase) -> String {
        switch phase {
        case .morning: return "sunrise"
        case .midday: return "sun.max"
        case .evening: return "moon.stars"
        }
    }

    private func phaseLabel(_ phase: DayPhase) -> String {
        switch phase {
        case .morning: return "Morning"
        case .midday: return "Midday"
        case .evening: return "Evening"
        }
    }
}
