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
    /// Static content that doesn't change during the activity
    public struct ContentState: Codable, Hashable {
        /// Remaining time in seconds
        var remainingSeconds: TimeInterval

        /// Timer mode (focus, short break, long break)
        var mode: TimerMode

        /// Timer state (running, paused, completed)
        var state: TimerState

        /// Display time string (MM:SS)
        var displayTime: String

        /// End date for countdown (used by Dynamic Island)
        var timerEndDate: Date
    }

    /// Session count (static across activity lifetime)
    var sessionCount: Int
}
