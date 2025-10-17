//
//  TimerLiveActivityWidget.swift
//  tomatoclockisland
//
//  Created on 2025-10-14
//

import ActivityKit
import WidgetKit
import SwiftUI

@main
struct TomatoClockIslandBundle: WidgetBundle {
    var body: some Widget {
        TimerLiveActivityWidget()
    }
}

struct TimerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            TimerLockScreenView(context: context)
                .activityBackgroundTint(.clear)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let snapshot = TimerIslandSnapshot(context: context)
            return DynamicIsland {
            DynamicIslandExpandedRegion(.leading) {
                ModeBadge(snapshot: snapshot)
            }

            DynamicIslandExpandedRegion(.center) {
                VStack(alignment: .leading, spacing: 8) {
                    // Use automatic countdown timer for real-time updates
                    snapshot.timerText()
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                    Text(snapshot.statusLine)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            DynamicIslandExpandedRegion(.trailing) {
                VStack(alignment: .trailing, spacing: 6) {
                    snapshot.timerText()
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundStyle(snapshot.timerColor)
                    ProgressView(value: snapshot.elapsed, total: snapshot.total)
                        .progressViewStyle(.linear)
                        .tint(snapshot.accentColor)
                }
            }

            DynamicIslandExpandedRegion(.bottom) {
                HStack {
                    Label("Session #\(snapshot.sessionNumber)", systemImage: "flame")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(snapshot.modeDescription)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
        } compactLeading: {
            Image(systemName: snapshot.symbolName)
                .font(.title3)
                .foregroundStyle(snapshot.accentColor)
        } compactTrailing: {
            snapshot.timerText()
                .font(.caption)
                .bold()
                .monospacedDigit()
                .foregroundStyle(snapshot.timerColor)
        } minimal: {
            Image(systemName: snapshot.symbolName)
                .foregroundStyle(snapshot.accentColor)
        }
        .keylineTint(snapshot.accentColor)
        }
    }
}

private struct TimerLockScreenView: View {
    let context: ActivityViewContext<TimerActivityAttributes>

    private var snapshot: TimerIslandSnapshot { TimerIslandSnapshot(context: context) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ModeBadge(snapshot: snapshot)
                Spacer()
                StatusBadge(snapshot: snapshot)
            }

            HStack(alignment: .lastTextBaseline, spacing: 10) {
                // Use automatic countdown timer for real-time updates
                snapshot.timerText()
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.9)
                Text(snapshot.statusLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .minimumScaleFactor(0.9)
            }

            ProgressView(value: snapshot.elapsed, total: snapshot.total) {
                Text(snapshot.statusLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .progressViewStyle(.linear)
            .tint(snapshot.accentColor)

            HStack {
                Label("Session #\(snapshot.sessionNumber)", systemImage: "flame")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(snapshot.modeDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, 10)
        .widgetURL(URL(string: "tomatoclock://timer"))
    }
}

private struct ModeBadge: View {
    let snapshot: TimerIslandSnapshot

    var body: some View {
        Label(snapshot.modeLabel, systemImage: snapshot.symbolName)
            .font(.caption)
            .bold()
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(snapshot.accentColor.opacity(0.18))
            )
            .foregroundStyle(snapshot.accentColor)
    }
}

private struct StatusBadge: View {
    let snapshot: TimerIslandSnapshot

    var body: some View {
        Text(snapshot.statusBadgeText)
            .font(.caption)
            .bold()
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                Capsule(style: .continuous)
                    .fill(snapshot.statusBadgeColor.opacity(0.25))
            )
            .foregroundStyle(snapshot.statusBadgeColor)
    }
}

private struct TimerIslandSnapshot {
    let context: ActivityViewContext<TimerActivityAttributes>

    var modeIdentifier: String { context.state.modeIdentifier }
    var stateIdentifier: String { context.state.stateIdentifier }

    var remaining: TimeInterval { context.state.remainingSeconds }
    var total: TimeInterval { max(context.state.totalDuration, 1) }
    var elapsed: TimeInterval { min(total, max(0, total - remaining)) }

    var accentColor: Color {
        switch modeIdentifier {
        case "focus":
            return .red
        case "shortBreak":
            return .teal
        case "longBreak":
            return .blue
        default:
            return .pink
        }
    }

    var statusBadgeColor: Color {
        if isPaused { return .yellow }
        if isCompleted { return .green }
        return accentColor
    }

    var timerColor: Color {
        if isPaused { return .yellow }
        if isCompleted { return .green }
        return .primary
    }

    var symbolName: String {
        switch modeIdentifier {
        case "focus":
            return "timer"
        case "shortBreak":
            return "cup.and.saucer.fill"
        case "longBreak":
            return "bed.double.fill"
        default:
            return "clock"
        }
    }

    var modeLabel: String { context.state.modeLabel }
    var modeDescription: String { context.state.modeDisplayName }
    var statusLine: String {
        if isCompleted { return "Completed" }
        if isPaused { return "Paused" }
        return modeDescription
    }

    var statusBadgeText: String {
        if isCompleted { return "DONE" }
        if isPaused { return "PAUSED" }
        return "ACTIVE"
    }

    var sessionNumber: Int { max(1, context.state.sessionNumber) }

    var isPaused: Bool { stateIdentifier == "paused" }
    var isCompleted: Bool { stateIdentifier == "completed" }

    func timerText() -> Text {
        Text(context.state.timerEndDate, style: .timer)
    }
}
