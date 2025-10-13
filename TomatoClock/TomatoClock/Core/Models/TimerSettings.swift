//
//  TimerSettings.swift
//  TomatoClock
//
//  Created on 2025-10-13
//

import Foundation

/// User-configurable timer duration settings
struct TimerSettings: Codable, Equatable {
    var focusDuration: TimeInterval      // in seconds
    var shortBreakDuration: TimeInterval // in seconds
    var longBreakDuration: TimeInterval  // in seconds
    var autoRestMode: RestMode           // automatic rest after focus

    /// Default Pomodoro settings
    static let `default` = TimerSettings(
        focusDuration: 25 * 60,      // 25 minutes
        shortBreakDuration: 5 * 60,   // 5 minutes
        longBreakDuration: 15 * 60,   // 15 minutes
        autoRestMode: .shortBreak     // default to short break
    )

    /// Get duration for a specific mode
    func duration(for mode: TimerMode) -> TimeInterval {
        switch mode {
        case .focus:
            return focusDuration
        case .shortBreak:
            return shortBreakDuration
        case .longBreak:
            return longBreakDuration
        }
    }

    /// Validate that all durations are within acceptable range (1-60 minutes)
    var isValid: Bool {
        let minDuration: TimeInterval = 60      // 1 minute
        let maxDuration: TimeInterval = 60 * 60 // 60 minutes

        return focusDuration >= minDuration && focusDuration <= maxDuration &&
               shortBreakDuration >= minDuration && shortBreakDuration <= maxDuration &&
               longBreakDuration >= minDuration && longBreakDuration <= maxDuration
    }
}
