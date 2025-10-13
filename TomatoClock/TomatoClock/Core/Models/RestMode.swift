//
//  RestMode.swift
//  TomatoClock
//
//  Created on 2025-10-13
//

import Foundation

/// Rest mode options after focus session completes
enum RestMode: String, Codable, CaseIterable {
    case none           // No automatic rest
    case shortBreak     // 5-minute short break
    case longBreak      // 15-minute long break

    /// Display name for UI
    var displayName: String {
        switch self {
        case .none:
            return "不休息"
        case .shortBreak:
            return "短休息"
        case .longBreak:
            return "長休息"
        }
    }

    /// Icon for UI
    var icon: String {
        switch self {
        case .none:
            return "xmark.circle"
        case .shortBreak:
            return "cup.and.saucer.fill"
        case .longBreak:
            return "bed.double.fill"
        }
    }

    /// Convert to TimerMode (returns nil for .none)
    var timerMode: TimerMode? {
        switch self {
        case .none:
            return nil
        case .shortBreak:
            return .shortBreak
        case .longBreak:
            return .longBreak
        }
    }
}
