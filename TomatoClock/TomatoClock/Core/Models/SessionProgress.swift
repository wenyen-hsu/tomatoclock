//
//  SessionProgress.swift
//  TomatoClock
//
//  Created on 2025-10-11
//

import Foundation

/// Tracks completed Pomodoro sessions for current day
struct SessionProgress: Codable {
    /// Number of completed focus sessions today
    let completedCount: Int

    /// Date of last session count reset (start of day)
    let lastResetDate: Date

    /// Current position in 4-session cycle (0-3)
    var cyclePosition: Int {
        return completedCount % 4
    }

    /// Number of filled progress dots (0-4)
    var filledDots: Int {
        return cyclePosition
    }

    /// Should trigger long break after next session?
    var shouldTriggerLongBreak: Bool {
        return cyclePosition == 3  // 4th session in cycle
    }

    /// Default state: Zero sessions, today's date
    static var `default`: SessionProgress {
        return SessionProgress(
            completedCount: 0,
            lastResetDate: Calendar.current.startOfDay(for: Date())
        )
    }
}

extension SessionProgress {
    /// Check if reset needed, return updated progress if so
    func checkAndReset(currentDate: Date = Date()) -> SessionProgress {
        let today = Calendar.current.startOfDay(for: currentDate)
        let lastReset = Calendar.current.startOfDay(for: lastResetDate)

        if !Calendar.current.isDate(lastReset, inSameDayAs: today) {
            // New day detected, reset counter
            return SessionProgress(completedCount: 0, lastResetDate: today)
        }
        return self
    }

    /// Increment session count (after focus session completion)
    func incrementSession() -> SessionProgress {
        return SessionProgress(
            completedCount: completedCount + 1,
            lastResetDate: lastResetDate
        )
    }
}
