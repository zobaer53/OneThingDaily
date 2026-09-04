import ActivityKit
import WidgetKit
import SwiftUI
import OneThingTodayDomain
import OneThingTodayData

/// The Live Activity itself: Lock Screen card + all four Dynamic Island
/// presentations. This file only lays out `FocusActivityAttributes.ContentState`
/// — it has no idea a relay, an alarm, or SwiftData exist on the other side
/// of that snapshot.
struct FocusActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            FocusLockScreenView(state: context.state)
                .activityBackgroundTint(.black)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: symbolName(for: context.state))
                        .foregroundStyle(.orange)
                        .font(.title2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isDone {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title2)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(taskLine(for: context.state))
                        .font(.headline)
                        .lineLimit(2)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(phaseLabel(for: context.state.phase))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: symbolName(for: context.state))
                    .foregroundStyle(.orange)
            } compactTrailing: {
                if context.state.isDone {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Text(compactPhaseLabel(for: context.state.phase))
                        .font(.caption2)
                }
            } minimal: {
                Image(systemName: symbolName(for: context.state))
                    .foregroundStyle(context.state.isDone ? .green : .orange)
            }
        }
    }

    private func symbolName(for state: FocusActivityAttributes.ContentState) -> String {
        if state.isDone { return "checkmark.circle.fill" }
        switch state.phase {
        case .morning: return "sunrise.fill"
        case .midday: return "sun.max.fill"
        case .evening: return "moon.stars.fill"
        }
    }

    private func phaseLabel(for phase: DayPhase) -> String {
        switch phase {
        case .morning: return "This morning"
        case .midday: return "Still going"
        case .evening: return "Tonight"
        }
    }

    private func compactPhaseLabel(for phase: DayPhase) -> String {
        switch phase {
        case .morning: return "AM"
        case .midday: return "•"
        case .evening: return "PM"
        }
    }

    private func taskLine(for state: FocusActivityAttributes.ContentState) -> String {
        state.taskText.isEmpty ? "One thing today" : state.taskText
    }
}
