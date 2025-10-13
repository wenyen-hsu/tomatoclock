//
//  TimerEngine.swift
//  TomatoClock
//
//  Created on 2025-10-11
//

import Foundation
import Combine
import ActivityKit

/// Core timer engine managing state machine, countdown logic, and time tracking
class TimerEngine: TimerEngineProtocol {
    // MARK: - Published Properties

    private(set) var currentData: TimerData

    var statePublisher: AnyPublisher<TimerState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var tickPublisher: AnyPublisher<TimeInterval, Never> {
        tickSubject.eraseToAnyPublisher()
    }

    // MARK: - Private Properties

    private let stateSubject = PassthroughSubject<TimerState, Never>()
    private let tickSubject = PassthroughSubject<TimeInterval, Never>()

    private let persistence: PersistenceServiceProtocol
    private let notifications: NotificationServiceProtocol
    private let sessionManager: SessionManagerProtocol

    private var timerCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()

    private static let notificationIdentifier = "com.tomatoclock.timer.completion"

    // User-configurable timer durations
    private(set) var timerSettings: TimerSettings

    // Live Activity tracking
    @available(iOS 16.1, *)
    private var currentActivity: Activity<TimerActivityAttributes>?

    // MARK: - Initialization

    init(
        persistence: PersistenceServiceProtocol,
        notifications: NotificationServiceProtocol,
        sessionManager: SessionManagerProtocol
    ) {
        self.persistence = persistence
        self.notifications = notifications
        self.sessionManager = sessionManager

        // Load timer settings or use default
        self.timerSettings = persistence.loadTimerSettings() ?? .default

        let focusDuration = timerSettings.duration(for: .focus)

        // Initialize with default data using custom duration
        self.currentData = TimerData(
            mode: .focus,
            state: .ready,
            remainingSeconds: focusDuration,
            totalDuration: focusDuration,
            startUptime: nil,
            elapsedBeforeStart: 0,
            savedAt: Date()
        )
    }

    // MARK: - State Management

    func start() throws {
        guard currentData.state.canStart else {
            throw TimerError.invalidStateTransition(
                from: currentData.state,
                to: .running
            )
        }

        // Capture monotonic start time
        let startUptime = ProcessInfo.processInfo.systemUptime

        // Update state
        currentData = TimerData(
            mode: currentData.mode,
            state: .running,
            remainingSeconds: currentData.remainingSeconds,
            totalDuration: currentData.totalDuration,
            startUptime: startUptime,
            elapsedBeforeStart: currentData.elapsedBeforeStart,
            savedAt: Date()
        )

        // Start timer
        startTimer()

        // Publish immediate tick so UI updates right away
        tickSubject.send(currentData.currentRemaining())

        // Schedule completion notification
        scheduleCompletionNotification()

        // Publish state change
        stateSubject.send(.running)

        // Start Live Activity
        if #available(iOS 16.1, *) {
            startLiveActivity()
        }

        // Auto-save
        saveState()
    }

    func pause() throws {
        guard currentData.state.canPause else {
            throw TimerError.invalidStateTransition(
                from: currentData.state,
                to: .paused
            )
        }

        // Calculate elapsed time before pausing
        let elapsed = currentData.currentElapsed()

        // Stop timer
        stopTimer()

        // Cancel notification
        notifications.cancelNotification(identifier: Self.notificationIdentifier)

        // Update state
        currentData = TimerData(
            mode: currentData.mode,
            state: .paused,
            remainingSeconds: currentData.remainingSeconds,
            totalDuration: currentData.totalDuration,
            startUptime: nil,
            elapsedBeforeStart: elapsed,
            savedAt: Date()
        )

        // Publish state change
        stateSubject.send(.paused)

        // End Live Activity
        if #available(iOS 16.1, *) {
            endLiveActivity()
        }

        // Auto-save
        saveState()
    }

    func resume() throws {
        guard currentData.state.canResume else {
            throw TimerError.invalidStateTransition(
                from: currentData.state,
                to: .running
            )
        }

        // Capture new monotonic start time
        let startUptime = ProcessInfo.processInfo.systemUptime

        // Update state
        currentData = TimerData(
            mode: currentData.mode,
            state: .running,
            remainingSeconds: currentData.remainingSeconds,
            totalDuration: currentData.totalDuration,
            startUptime: startUptime,
            elapsedBeforeStart: currentData.elapsedBeforeStart,
            savedAt: Date()
        )

        // Restart timer
        startTimer()

        // Publish immediate tick so UI updates right away
        tickSubject.send(currentData.currentRemaining())

        // Reschedule notification
        scheduleCompletionNotification()

        // Publish state change
        stateSubject.send(.running)

        // Restart Live Activity
        if #available(iOS 16.1, *) {
            startLiveActivity()
        }

        // Auto-save
        saveState()
    }

    func reset() {
        // Stop timer
        stopTimer()

        // Cancel notifications
        notifications.cancelNotification(identifier: Self.notificationIdentifier)

        // Always reset back to focus mode with full configured duration
        let duration = timerSettings.duration(for: .focus)

        // Reset to ready state with full duration
        currentData = TimerData(
            mode: .focus,
            state: .ready,
            remainingSeconds: duration,
            totalDuration: duration,
            startUptime: nil,
            elapsedBeforeStart: 0,
            savedAt: Date()
        )

        // Publish state change
        stateSubject.send(.ready)

        // Publish tick to update UI display time
        tickSubject.send(duration)

        // End Live Activity
        if #available(iOS 16.1, *) {
            endLiveActivity()
        }

        // Auto-save
        saveState()
    }

    func switchMode(to mode: TimerMode) {
        // Stop current timer
        stopTimer()

        // Cancel notifications
        notifications.cancelNotification(identifier: Self.notificationIdentifier)

        // Get duration from settings
        let duration = timerSettings.duration(for: mode)

        // Switch mode and reset
        currentData = TimerData(
            mode: mode,
            state: .ready,
            remainingSeconds: duration,
            totalDuration: duration,
            startUptime: nil,
            elapsedBeforeStart: 0,
            savedAt: Date()
        )

        // Publish tick to update UI display time after mode switch
        tickSubject.send(duration)

        // Publish state change
        stateSubject.send(.ready)

        // Auto-save
        saveState()
    }

    // MARK: - Persistence

    @discardableResult
    func loadState() -> Bool {
        guard let savedData = persistence.loadTimerData() else {
            return false
        }

        // Check if state is stale (> 1 hour old)
        if savedData.isStale {
            // Use default state
            return false
        }

        // Restore state
        currentData = savedData

        // If was running, don't auto-resume (user must manually resume)
        // But keep the elapsed time
        if currentData.state == .running {
            let elapsed = currentData.currentElapsed()
            currentData = TimerData(
                mode: currentData.mode,
                state: .paused,
                remainingSeconds: currentData.remainingSeconds,
                totalDuration: currentData.totalDuration,
                startUptime: nil,
                elapsedBeforeStart: elapsed,
                savedAt: Date()
            )
        }

        return true
    }

    func saveState() {
        do {
            try persistence.saveTimerData(currentData)
        } catch {
            // Log error but don't crash
            print("Failed to save timer state: \(error)")
        }
    }

    // MARK: - Private Methods

    private func startTimer() {
        // Create timer that fires every second
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.handleTick()
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func handleTick() {
        // Calculate remaining time
        let remaining = currentData.currentRemaining()

        // Publish tick
        tickSubject.send(remaining)

        // Update remaining time
        currentData = TimerData(
            mode: currentData.mode,
            state: currentData.state,
            remainingSeconds: remaining,
            totalDuration: currentData.totalDuration,
            startUptime: currentData.startUptime,
            elapsedBeforeStart: currentData.elapsedBeforeStart,
            savedAt: Date()
        )

        // Update Live Activity
        if #available(iOS 16.1, *) {
            updateLiveActivity()
        }

        // Check for completion
        if remaining <= 0 {
            handleCompletion()
        }
    }

    private func handleCompletion() {
        // Stop timer
        stopTimer()

        // Use the configured duration for this run
        let duration = currentData.totalDuration

        // Update state to completed
        currentData = TimerData(
            mode: currentData.mode,
            state: .completed,
            remainingSeconds: 0,
            totalDuration: duration,
            startUptime: nil,
            elapsedBeforeStart: duration,
            savedAt: Date()
        )

        // Record session if focus mode
        if currentData.mode == .focus {
            sessionManager.recordCompletedSession()
        }

        // Publish state change
        stateSubject.send(.completed)

        // End Live Activity
        if #available(iOS 16.1, *) {
            endLiveActivity()
        }

        // Auto-save
        saveState()

        // Auto-switch to rest mode if focus just completed
        if currentData.mode == .focus, let restMode = timerSettings.autoRestMode.timerMode {
            // Delay to allow UI to show completion briefly, then start rest automatically
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self else { return }

                // Ensure we are still in the completed focus state before auto-switching
                guard self.currentData.mode == .focus,
                      self.currentData.state == .completed else {
                    return
                }

                self.switchMode(to: restMode)

                do {
                    try self.start()
                } catch {
                    print("Failed to auto-start rest session: \(error)")
                }
            }
        } else if currentData.mode != .focus {
            // After rest finishes, return to focus mode ready state
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self else { return }

                // Only switch if we are still on a completed rest
                guard self.currentData.state == .completed,
                      self.currentData.mode != .focus else {
                    return
                }

                self.switchMode(to: .focus)
            }
        }
    }

    private func scheduleCompletionNotification() {
        let remaining = currentData.currentRemaining()
        let fireDate = Date().addingTimeInterval(remaining)

        do {
            try notifications.scheduleCompletionNotification(
                for: currentData.mode,
                at: fireDate,
                identifier: Self.notificationIdentifier
            )
        } catch {
            // Log error but don't throw - notifications are non-critical
            print("Failed to schedule notification: \(error)")
        }
    }

    // MARK: - Settings Management

    /// Update timer settings and reset current timer if in ready/completed state
    func updateSettings(_ newSettings: TimerSettings) {
        guard newSettings.isValid else {
            print("⚠️ Invalid timer settings, ignoring update")
            return
        }

        timerSettings = newSettings

        // Save settings
        do {
            try persistence.saveTimerSettings(newSettings)
        } catch {
            print("Failed to save timer settings: \(error)")
        }

        // If timer is NOT running or paused, update the remaining time
        if currentData.state == .ready || currentData.state == .completed {
            let newDuration = timerSettings.duration(for: currentData.mode)
            currentData = TimerData(
                mode: currentData.mode,
                state: .ready,
                remainingSeconds: newDuration,
                totalDuration: newDuration,
                startUptime: nil,
                elapsedBeforeStart: 0,
                savedAt: Date()
            )

            // Publish state change (in case we moved from completed to ready)
            stateSubject.send(.ready)

            // Publish tick to update UI
            tickSubject.send(newDuration)

            // Save state
            saveState()
        }
    }

    // MARK: - Live Activity Management

    @available(iOS 16.1, *)
    private func startLiveActivity() {
        // End any existing activity first
        endLiveActivity()

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }

        let remaining = currentData.currentRemaining()
        let timerEndDate = Date().addingTimeInterval(remaining)

        let attributes = TimerActivityAttributes(
            sessionCount: sessionManager.currentProgress.completedCount
        )

        let contentState = TimerActivityAttributes.ContentState(
            remainingSeconds: remaining,
            mode: currentData.mode,
            state: currentData.state,
            displayTime: remaining.formatAsMMSS(),
            timerEndDate: timerEndDate
        )

        do {
            let activity = try Activity<TimerActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            print("✅ Live Activity started: \(activity.id)")
        } catch {
            print("❌ Failed to start Live Activity: \(error)")
        }
    }

    @available(iOS 16.1, *)
    private func updateLiveActivity() {
        guard let activity = currentActivity else { return }

        let remaining = currentData.currentRemaining()
        let timerEndDate = Date().addingTimeInterval(remaining)

        let contentState = TimerActivityAttributes.ContentState(
            remainingSeconds: remaining,
            mode: currentData.mode,
            state: currentData.state,
            displayTime: remaining.formatAsMMSS(),
            timerEndDate: timerEndDate
        )

        Task {
            await activity.update(.init(state: contentState, staleDate: nil))
        }
    }

    @available(iOS 16.1, *)
    private func endLiveActivity() {
        guard let activity = currentActivity else { return }

        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
            print("✅ Live Activity ended")
        }
    }
}
