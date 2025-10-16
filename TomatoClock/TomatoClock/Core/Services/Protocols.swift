//
//  Protocols.swift
//  TomatoClock
//
//  Created on 2025-10-11
//

import Foundation
import Combine
import UserNotifications

// MARK: - Timer Engine Protocol

/// Core timer logic - state machine, countdown, monotonic time tracking
protocol TimerEngineProtocol: AnyObject {
    /// Current timer data (mode, state, remaining time)
    var currentData: TimerData { get }

    /// Current timer settings (user-configurable durations)
    var timerSettings: TimerSettings { get }

    /// Publisher for timer state changes
    var statePublisher: AnyPublisher<TimerState, Never> { get }

    /// Publisher for tick events (every second while running)
    var tickPublisher: AnyPublisher<TimeInterval, Never> { get }

    /// Start timer from ready state
    /// - Throws: TimerError.invalidStateTransition if not in ready state
    func start() throws

    /// Pause running timer
    /// - Throws: TimerError.invalidStateTransition if not in running state
    func pause() throws

    /// Resume paused timer
    /// - Throws: TimerError.invalidStateTransition if not in paused state
    func resume() throws

    /// Reset timer to ready state with full duration
    func reset()

    /// Switch to different mode (resets timer)
    /// - Parameter mode: New timer mode (focus/shortBreak/longBreak)
    func switchMode(to mode: TimerMode)

    /// Update timer settings
    /// - Parameter newSettings: New timer duration settings
    func updateSettings(_ newSettings: TimerSettings)

    /// Load saved state from persistence
    /// - Returns: true if state was restored, false if using default
    @discardableResult
    func loadState() -> Bool

    /// Save current state to persistence
    func saveState()
}

// MARK: - Session Manager Protocol

/// Track completed sessions, manage 4-Pomodoro cycle, daily reset logic
protocol SessionManagerProtocol: AnyObject {
    /// Current session progress (count, date, cycle position)
    var currentProgress: SessionProgress { get }

    /// Publisher for session progress updates
    var progressPublisher: AnyPublisher<SessionProgress, Never> { get }

    /// Record a completed focus session
    /// - Returns: Updated progress with incremented count
    @discardableResult
    func recordCompletedSession() -> SessionProgress

    /// Get recommended next mode based on cycle position
    /// - Returns: .shortBreak for 1st-3rd session, .longBreak for 4th
    func recommendedNextMode() -> TimerMode

    /// Reset daily count if new day detected
    /// - Returns: true if reset occurred
    @discardableResult
    func checkAndResetIfNewDay() -> Bool

    /// Load saved progress from persistence
    func loadProgress()

    /// Save current progress to persistence
    func saveProgress()
}

// MARK: - Notification Service Protocol

/// Schedule/cancel local notifications for timer completion
protocol NotificationServiceProtocol: AnyObject {
    /// Check notification authorization status
    var authorizationStatus: AnyPublisher<UNAuthorizationStatus, Never> { get }

    /// Request notification permissions from user
    /// - Returns: true if granted, false if denied
    func requestAuthorization() async throws -> Bool

    /// Schedule notification for timer completion
    /// - Parameters:
    ///   - mode: Timer mode (determines notification text)
    ///   - fireDate: When to fire notification
    ///   - identifier: Unique identifier for cancellation
    func scheduleCompletionNotification(
        for mode: TimerMode,
        nextMode: TimerMode?,
        settings: TimerSettings?,
        at fireDate: Date,
        identifier: String
    ) throws

    /// Cancel pending notification by identifier
    /// - Parameter identifier: Notification identifier to cancel
    func cancelNotification(identifier: String)

    /// Cancel all pending notifications
    func cancelAllNotifications()
}
