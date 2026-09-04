import SwiftUI
import OneThingTodayDomain
import OneThingTodayData

/// What shows on the Lock Screen. Kept to one glance's worth of
/// information on purpose — this is the whole point of the app: nothing
/// else to read, nothing else to manage.
struct FocusLockScreenView: View {
    let state: FocusActivityAttributes.ContentState

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbolName)
                .font(.title2)
                .foregroundStyle(state.isDone ? .green : .orange)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(eyebrow)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))

                Text(state.taskText.isEmpty ? "One thing today" : state.taskText)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }

            Spacer()

            if state.isDone {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
            }
        }
        .padding(16)
    }

    private var symbolName: String {
        if state.isDone { return "checkmark.circle.fill" }
        switch state.phase {
        case .morning: return "sunrise.fill"
        case .midday: return "sun.max.fill"
        case .evening: return "moon.stars.fill"
        }
    }

    private var eyebrow: String {
        if state.isDone { return "Done for today" }
        switch state.phase {
        case .morning: return "Today's one thing"
        case .midday: return "Still on it"
        case .evening: return "How'd it go?"
        }
    }
}
