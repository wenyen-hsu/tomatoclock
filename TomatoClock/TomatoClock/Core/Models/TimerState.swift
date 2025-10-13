//
//  TimerState.swift
//  TomatoClock
//
//  Created on 2025-10-11
//

import Foundation

/// Lifecycle state of the timer
enum TimerState: String, Codable {
    case ready      // Timer initialized, not started
    case running    // Timer actively counting down
    case paused     // Timer stopped mid-countdown
    case completed  // Timer reached 00:00

    /// Can the timer be started from this state?
    var canStart: Bool {
        return self == .ready
    }

    /// Can the timer be paused from this state?
    var canPause: Bool {
        return self == .running
    }

    /// Can the timer be resumed from this state?
    var canResume: Bool {
        return self == .paused
    }

    /// Can the timer be reset from this state?
    var canReset: Bool {
        return self != .ready
    }

    /// Is the timer in an active state (running or paused)?
    var isActive: Bool {
        return self == .running || self == .paused
    }
}
