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

    // Flattened steps derived from the configured flow.
    private var flowSteps: [TimerSequenceStep]

    // Current index inside the repeating flow sequence.
    private var currentStepIndex: Int

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

        // Load timer settings or use default and guarantee a valid flow sequence
        var loadedSettings = persistence.loadTimerSettings() ?? .default
        loadedSettings.flow.ensureMinimumCycle()
        loadedSettings.alignBaseDurationsWithFlow()

        var normalizedSettings = loadedSettings
        var preparedSteps = normalizedSettings.flow.steps
        if preparedSteps.isEmpty {
            let fallbackCycle = FocusCycleConfiguration(focusDuration: normalizedSettings.focusDuration)
            normalizedSettings.flow = TimerFlowConfiguration(cycles: [fallbackCycle])
            preparedSteps = normalizedSettings.flow.steps
        }

        self.timerSettings = normalizedSettings
        self.flowSteps = preparedSteps
        self.currentStepIndex = 0

        let initialStep = preparedSteps[currentStepIndex]

        // Initialize with default data using the first step's duration
        self.currentData = TimerData(
            mode: initialStep.mode,
            state: .ready,
            remainingSeconds: initialStep.duration,
            totalDuration: initialStep.duration,
            startUptime: nil,
            elapsedBeforeStart: 0,
            savedAt: Date(),
            sequenceIndex: currentStepIndex
        )

        // Persist sanitized settings if necessary
        try? persistence.saveTimerSettings(timerSettings)
    }

    // MARK: - State Management

    func start() throws {
        guard currentData.state.canStart else {
            throw TimerError.invalidStateTransition(
                from: currentData.state,
                to: .running
            )
        }

        rebuildFlowSteps(resetIndex: false)

        guard !flowSteps.isEmpty else {
            throw TimerError.invalidStateTransition(
                from: currentData.state,
                to: .running
            )
        }

        // Capture monotonic start time
        let startUptime = ProcessInfo.processInfo.systemUptime

        // Update state using the current step duration
        let step = flowSteps[currentStepIndex]
        currentData = TimerData(
            mode: step.mode,
            state: .running,
            remainingSeconds: currentData.currentRemaining(),
            totalDuration: step.duration,
            startUptime: startUptime,
            elapsedBeforeStart: currentData.elapsedBeforeStart,
            savedAt: Date(),
            sequenceIndex: currentStepIndex
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
        let step = flowSteps[currentStepIndex]
        currentData = TimerData(
            mode: step.mode,
            state: .paused,
            remainingSeconds: currentData.currentRemaining(),
            totalDuration: step.duration,
            startUptime: nil,
            elapsedBeforeStart: elapsed,
            savedAt: Date(),
            sequenceIndex: currentStepIndex
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
        let step = flowSteps[currentStepIndex]
        currentData = TimerData(
            mode: step.mode,
            state: .running,
            remainingSeconds: currentData.currentRemaining(),
            totalDuration: step.duration,
            startUptime: startUptime,
            elapsedBeforeStart: currentData.elapsedBeforeStart,
            savedAt: Date(),
            sequenceIndex: currentStepIndex
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

        rebuildFlowSteps(resetIndex: true)

        // Reset to ready state with the first step duration
        transitionToReadyStep(at: currentStepIndex)

        // End Live Activity
        if #available(iOS 16.1, *) {
            endLiveActivity()
        }
    }

    func switchMode(to mode: TimerMode) {
        // Stop current timer
        stopTimer()

        // Cancel notifications
        notifications.cancelNotification(identifier: Self.notificationIdentifier)

        rebuildFlowSteps(resetIndex: false)

        if let targetIndex = flowSteps.firstIndex(where: { $0.mode == mode }) {
            currentStepIndex = targetIndex
        } else {
            currentStepIndex = 0
        }

        transitionToReadyStep(at: currentStepIndex)
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

        rebuildFlowSteps(resetIndex: false)

        if flowSteps.isEmpty {
            return false
        }

        currentStepIndex = min(savedData.sequenceIndex, flowSteps.count - 1)
        let step = flowSteps[currentStepIndex]

        // Restore state with the current flow step duration
        currentData = TimerData(
            mode: step.mode,
            state: savedData.state,
            remainingSeconds: min(savedData.remainingSeconds, step.duration),
            totalDuration: step.duration,
            startUptime: savedData.startUptime,
            elapsedBeforeStart: min(savedData.elapsedBeforeStart, step.duration),
            savedAt: savedData.savedAt,
            sequenceIndex: currentStepIndex
        )

        // If was running, don't auto-resume (user must manually resume)
        // But keep the elapsed time
        if currentData.state == .running {
            let elapsed = currentData.currentElapsed()
            currentData = TimerData(
                mode: currentData.mode,
                state: .paused,
                remainingSeconds: currentData.currentRemaining(),
                totalDuration: currentData.totalDuration,
                startUptime: nil,
                elapsedBeforeStart: elapsed,
                savedAt: Date(),
                sequenceIndex: currentStepIndex
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
            totalDuration: flowSteps[currentStepIndex].duration,
            startUptime: currentData.startUptime,
            elapsedBeforeStart: currentData.elapsedBeforeStart,
            savedAt: Date(),
            sequenceIndex: currentStepIndex
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

        guard !flowSteps.isEmpty else { return }

        let completedStep = flowSteps[currentStepIndex]
        let duration = completedStep.duration

        // Update state to completed
        currentData = TimerData(
            mode: completedStep.mode,
            state: .completed,
            remainingSeconds: 0,
            totalDuration: duration,
            startUptime: nil,
            elapsedBeforeStart: duration,
            savedAt: Date(),
            sequenceIndex: currentStepIndex
        )

        // Record session if focus mode
        if completedStep.kind == .focus {
            sessionManager.recordCompletedSession()
        }

        // Publish state change
        stateSubject.send(.completed)

        // End Live Activity
        if #available(iOS 16.1, *) {
            endLiveActivity()
        }

        // Auto-save current completed state
        saveState()

        let completedIndex = currentStepIndex

        // After a short delay, move to the next step in the flow.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }

            // Ensure we are still on the same completed step before advancing.
            guard self.currentData.state == .completed,
                  self.currentStepIndex == completedIndex else {
                return
            }

            self.rebuildFlowSteps(resetIndex: false)

            guard !self.flowSteps.isEmpty else { return }

            let nextRawIndex = completedIndex + 1
            guard nextRawIndex < self.flowSteps.count else {
                return
            }

            self.transitionToReadyStep(at: nextRawIndex)

            do {
                try self.start()
            } catch {
                print("Failed to auto-start next session: \(error)")
            }
        }
    }

    private func rebuildFlowSteps(resetIndex: Bool) {
        timerSettings.flow.ensureMinimumCycle()
        timerSettings.alignBaseDurationsWithFlow()

        flowSteps = timerSettings.flow.steps
        if flowSteps.isEmpty {
            let fallbackCycle = FocusCycleConfiguration(focusDuration: timerSettings.focusDuration)
            flowSteps = fallbackCycle.sequenceSteps
            timerSettings.flow = TimerFlowConfiguration(cycles: [fallbackCycle])
        }

        if resetIndex {
            currentStepIndex = 0
        } else if currentStepIndex >= flowSteps.count {
            currentStepIndex = flowSteps.isEmpty ? 0 : currentStepIndex % flowSteps.count
        }
    }

    private func normalizedIndex(_ index: Int) -> Int {
        guard !flowSteps.isEmpty else { return 0 }
        var value = index % flowSteps.count
        if value < 0 {
            value += flowSteps.count
        }
        return value
    }

    private func transitionToReadyStep(at index: Int) {
        guard !flowSteps.isEmpty else { return }

        currentStepIndex = normalizedIndex(index)
        let step = flowSteps[currentStepIndex]

        currentData = TimerData(
            mode: step.mode,
            state: .ready,
            remainingSeconds: step.duration,
            totalDuration: step.duration,
            startUptime: nil,
            elapsedBeforeStart: 0,
            savedAt: Date(),
            sequenceIndex: currentStepIndex
        )

        tickSubject.send(step.duration)
        stateSubject.send(.ready)
        saveState()
    }

    private func scheduleCompletionNotification() {
        let remaining = currentData.currentRemaining()
        let fireDate = Date().addingTimeInterval(remaining)

        // Determine the next mode for the notification content
        let nextIndex = normalizedIndex(currentStepIndex + 1)
        let nextMode = flowSteps.indices.contains(nextIndex) ? flowSteps[nextIndex].mode : nil

        do {
            try notifications.scheduleCompletionNotification(
                for: currentData.mode,
                nextMode: nextMode,
                settings: timerSettings,
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
        rebuildFlowSteps(resetIndex: false)

        // Save settings
        do {
            try persistence.saveTimerSettings(timerSettings)
        } catch {
            print("Failed to save timer settings: \(error)")
        }

        // If timer is NOT running or paused, update the remaining time by resetting the current step
        if currentData.state == .ready || currentData.state == .completed {
            transitionToReadyStep(at: currentStepIndex)
        } else {
            // Timer is active; adjust durations in-place without interrupting state
            guard !flowSteps.isEmpty else { return }

            let step = flowSteps[currentStepIndex]
            let remaining = min(currentData.currentRemaining(), step.duration)
            let elapsedBeforeStart = min(currentData.elapsedBeforeStart, step.duration)

            currentData = TimerData(
                mode: step.mode,
                state: currentData.state,
                remainingSeconds: remaining,
                totalDuration: step.duration,
                startUptime: currentData.startUptime,
                elapsedBeforeStart: elapsedBeforeStart,
                savedAt: Date(),
                sequenceIndex: currentStepIndex
            )

            tickSubject.send(currentData.currentRemaining())
            saveState()

            // Refresh outbound systems to reflect the new duration
            if currentData.state == .running {
                scheduleCompletionNotification()
                if #available(iOS 16.1, *) {
                    updateLiveActivity()
                }
            }
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

        // Use the convenience initializer with TimerMode and TimerState enums
        let contentState = TimerActivityAttributes.ContentState(
            remainingSeconds: remaining,
            totalDuration: currentData.totalDuration,
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

        // Use the convenience initializer with TimerMode and TimerState enums
        let contentState = TimerActivityAttributes.ContentState(
            remainingSeconds: remaining,
            totalDuration: currentData.totalDuration,
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
