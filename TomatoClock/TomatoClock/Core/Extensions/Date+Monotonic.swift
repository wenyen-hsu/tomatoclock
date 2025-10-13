//
//  Date+Monotonic.swift
//  TomatoClock
//
//  Created on 2025-10-11
//

import Foundation

extension TimeInterval {
    /// Format TimeInterval as MM:SS string
    func formatAsMMSS() -> String {
        let totalSeconds = Int(self)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

extension ProcessInfo {
    /// Current system uptime (monotonic time)
    static var currentUptime: TimeInterval {
        return ProcessInfo.processInfo.systemUptime
    }
}
