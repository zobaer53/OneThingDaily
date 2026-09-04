import SwiftUI

struct OnboardingView: View {
    @State var viewModel: OnboardingViewModel
    var onComplete: () -> Void

    @State private var step: Step = .welcome

    private enum Step: Int, CaseIterable {
        case welcome, times, permission
    }

    var body: some View {
        VStack(spacing: 24) {
            ProgressView(value: Double(step.rawValue + 1), total: Double(Step.allCases.count))
                .accessibilityHidden(true)
                .padding(.top, 20)

            Group {
                switch step {
                case .welcome:
                    OnboardingWelcomePage()
                case .times:
                    OnboardingTimesPage(viewModel: viewModel)
                case .permission:
                    OnboardingPermissionPage()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            footer
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    @ViewBuilder
    private var footer: some View {
        VStack(spacing: 12) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isStaticText)
            }

            Button(action: { Task { await advance() } }) {
                if viewModel.isScheduling {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text(primaryLabel)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isScheduling)

            if step != .welcome {
                Button("Back") {
                    step = Step(rawValue: step.rawValue - 1) ?? .welcome
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .disabled(viewModel.isScheduling)
            }
        }
    }

    private var primaryLabel: String {
        switch step {
        case .welcome, .times: return "Continue"
        case .permission: return "Enable & Finish"
        }
    }

    private func advance() async {
        switch step {
        case .welcome, .times:
            step = Step(rawValue: step.rawValue + 1) ?? .permission
        case .permission:
            if await viewModel.finish() {
                onComplete()
            }
        }
    }
}

private struct OnboardingWelcomePage: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("One thing, all day.")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)

                Text("Every day you pick exactly one focus — nothing else competes for your attention here.")
                    .font(.body)
                    .foregroundStyle(.secondary)

                OnboardingPoint(
                    icon: "sunrise",
                    title: "Morning",
                    detail: "An alarm asks what today's one thing is. It goes straight to your Lock Screen and Dynamic Island."
                )
                OnboardingPoint(
                    icon: "checkmark.circle",
                    title: "Midday",
                    detail: "A quick \"still on it?\" check-in keeps the Lock Screen card alive for the rest of the day."
                )
                OnboardingPoint(
                    icon: "moon.stars",
                    title: "Evening",
                    detail: "A short reflection closes out the day."
                )
                OnboardingPoint(
                    icon: "lock.shield",
                    title: "Fully private",
                    detail: "Everything — including the on-device AI that can sharpen a vague task into a concrete step — stays on your phone. No account, no server, nothing sent anywhere."
                )
            }
            .padding(.vertical, 8)
        }
    }
}

private struct OnboardingPoint: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct OnboardingTimesPage: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("When should we check in?")
                    .font(.title.bold())
                    .accessibilityAddTraits(.isHeader)

                Text("Pick a morning time to set today's focus, and an evening time to reflect. We'll also fit a midday check-in between them — that's what keeps the Lock Screen card current all day, instead of it going stale partway through.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 0) {
                    DatePicker("Morning check-in", selection: $viewModel.morningTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .padding(.vertical, 12)
                    Divider()
                    DatePicker("Evening reflection", selection: $viewModel.eveningTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .padding(.vertical, 12)
                }
                .padding(.horizontal, 16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(.vertical, 8)
        }
    }
}

private struct OnboardingPermissionPage: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("One permission to finish")
                    .font(.title.bold())
                    .accessibilityAddTraits(.isHeader)

                Text("On the next screen, iOS will ask to let One Thing Today schedule alarms. These are the three real alerts you just chose times for — morning, midday, and evening — and nothing else. There's no background tracking and no notifications beyond these.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Tap \"Enable & Finish\" below to grant it and schedule today's alarms.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
        }
    }
}
