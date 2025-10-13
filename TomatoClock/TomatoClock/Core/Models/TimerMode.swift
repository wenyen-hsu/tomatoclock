//
//  TimerMode.swift
//  TomatoClock
//
//  Created on 2025-10-11
//

import Foundation

/// Represents the three operating modes of the Pomodoro timer
enum TimerMode: String, Codable, CaseIterable {
    case focus
    case shortBreak
    case longBreak

    /// Duration in seconds for each mode
    var duration: TimeInterval {
        switch self {
        case .focus:
            return 25 * 60  // 1500 seconds
        case .shortBreak:
            return 5 * 60   // 300 seconds
        case .longBreak:
            return 15 * 60  // 900 seconds
        }
    }

    /// User-friendly display name
    var displayName: String {
        switch self {
        case .focus:
            return NSLocalizedString("mode.focus", comment: "Focus mode name")
        case .shortBreak:
            return NSLocalizedString("mode.shortBreak", comment: "Short break name")
        case .longBreak:
            return NSLocalizedString("mode.longBreak", comment: "Long break name")
        }
    }

    /// Label shown during timer ("FOCUS TIME", "BREAK TIME")
    var label: String {
        switch self {
        case .focus:
            return NSLocalizedString("label.focusTime", comment: "Focus time label")
        case .shortBreak, .longBreak:
            return NSLocalizedString("label.breakTime", comment: "Break time label")
        }
    }
}
