//
//  TimerActivityAttributes.swift
//  TomatoClock
//
//  Created on 2025-10-13
//

import Foundation
import ActivityKit

/// Attributes for Timer Live Activity (displayed in Dynamic Island and Lock Screen)
struct TimerActivityAttributes: ActivityAttributes {
    /// Dynamic content that updates during the activity
    public struct ContentState: Codable, Hashable {
        /// Remaining time in seconds
        var remainingSeconds: TimeInterval

        /// Total duration of current timer phase
        var totalDuration: TimeInterval

        /// Display time string (MM:SS)
        var displayTime: String

        /// End date for countdown (used by Dynamic Island for automatic countdown)
        var timerEndDate: Date

        /// Mode identifier ("focus", "shortBreak", "longBreak")
        var modeIdentifier: String

        /// Mode display name ("Focus", "Short Break", "Long Break")
        var modeDisplayName: String

        /// Mode label ("FOCUS TIME", "BREAK TIME")
        var modeLabel: String

        /// State identifier ("ready", "running", "paused", "completed")
        var stateIdentifier: String
    }

    /// Session count (static across activity lifetime)
    var sessionCount: Int
}

// MARK: - Convenience Initializers

extension TimerActivityAttributes.ContentState {
    /// Convenience initializer that accepts TimerMode and TimerState enums
    init(
        remainingSeconds: TimeInterval,
        totalDuration: TimeInterval,
        mode: TimerMode,
        state: TimerState,
        displayTime: String,
        timerEndDate: Date
    ) {
        self.remainingSeconds = remainingSeconds
        self.totalDuration = totalDuration
        self.modeIdentifier = mode.rawValue
        self.modeDisplayName = mode.displayName
        self.modeLabel = mode.label
        self.stateIdentifier = state.rawValue
        self.displayTime = displayTime
        self.timerEndDate = timerEndDate
    }
}
