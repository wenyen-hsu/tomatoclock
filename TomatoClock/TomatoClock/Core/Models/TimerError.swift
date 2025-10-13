//
//  TimerError.swift
//  TomatoClock
//
//  Created on 2025-10-11
//

import Foundation

/// Errors that can occur during timer operations
enum TimerError: Error {
    case invalidStateTransition(from: TimerState, to: TimerState)
    case persistenceFailure(underlyingError: Error)
    case notificationSchedulingFailed(underlyingError: Error)
}

extension TimerError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidStateTransition(let from, let to):
            return "Invalid state transition from \(from) to \(to)"
        case .persistenceFailure(let error):
            return "Failed to save/load state: \(error.localizedDescription)"
        case .notificationSchedulingFailed(let error):
            return "Failed to schedule notification: \(error.localizedDescription)"
        }
    }
}
