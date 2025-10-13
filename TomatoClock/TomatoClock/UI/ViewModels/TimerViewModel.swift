//
//  TimerViewModel.swift
//  TomatoClock
//
//  Created on 2025-10-11
//

import Foundation
import Combine
import SwiftUI

/// ViewModel bridging Core services and SwiftUI views
@MainActor
class TimerViewModel: ObservableObject {
    // MARK: - Published Properties

    /// Formatted time string (MM:SS)
    @Published var displayTime: String = "25:00"

    /// Current timer mode
    @Published var currentMode: TimerMode = .focus

    /// Current timer state
    @Published var currentState: TimerState = .ready

    /// Session count for display
    @Published var sessionCount: Int = 0

    /// Cycle position (0-3 for progress dots)
    @Published var cyclePosition: Int = 0

    /// Is timer currently running?
    @Published var isRunning: Bool = false

    /// Can start button be tapped?
    @Published var canStart: Bool = true

    /// Can pause button be tapped?
    @Published var canPause: Bool = false

    /// Can reset button be tapped?
    @Published var canReset: Bool = false

    // MARK: - Private Properties

    let timerEngine: TimerEngineProtocol
    private let sessionManager: SessionManagerProtocol
    private let notificationService: NotificationServiceProtocol

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        timerEngine: TimerEngineProtocol,
        sessionManager: SessionManagerProtocol,
        notificationService: NotificationServiceProtocol
    ) {
        self.timerEngine = timerEngine
        self.sessionManager = sessionManager
        self.notificationService = notificationService
    }

    // MARK: - Setup

    func setup() {
        // Load initial state from engine
        timerEngine.loadState()

        // Ensure initial ready state always shows focus duration
        if timerEngine.currentData.state == .ready,
           timerEngine.currentData.mode != .focus {
            timerEngine.switchMode(to: .focus)
        }

        updateFromEngine()

        // Subscribe to timer ticks
        timerEngine.tickPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] remainingSeconds in
                self?.displayTime = Self.formatTime(remainingSeconds)
            }
            .store(in: &cancellables)

        // Subscribe to state changes
        timerEngine.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }

                self.currentState = state
                self.currentMode = self.timerEngine.currentData.mode
                self.updateButtonStates()
            }
            .store(in: &cancellables)

        // Subscribe to session progress
        sessionManager.progressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.sessionCount = progress.completedCount
                self?.cyclePosition = progress.cyclePosition
            }
            .store(in: &cancellables)

        // Initialize session data
        sessionCount = sessionManager.currentProgress.completedCount
        cyclePosition = sessionManager.currentProgress.cyclePosition
    }

    // MARK: - User Actions

    func startTapped() {
        do {
            if currentState == .paused {
                try timerEngine.resume()
            } else {
                try timerEngine.start()
            }
        } catch {
            // Handle error - in production, show alert
            print("Failed to start timer: \(error)")
        }
    }

    func pauseTapped() {
        do {
            try timerEngine.pause()
        } catch {
            print("Failed to pause timer: \(error)")
        }
    }

    func resetTapped() {
        timerEngine.reset()
    }

    func modeSelected(_ mode: TimerMode) {
        timerEngine.switchMode(to: mode)
        currentMode = mode
    }

    func updateTimerSettings(_ settings: TimerSettings) {
        timerEngine.updateSettings(settings)
        // Update display time if changed
        displayTime = Self.formatTime(timerEngine.currentData.currentRemaining())
    }

    func updateRestMode(_ mode: RestMode) {
        var updatedSettings = timerEngine.timerSettings
        updatedSettings.autoRestMode = mode
        timerEngine.updateSettings(updatedSettings)
    }

    // MARK: - Lifecycle

    func saveState() {
        timerEngine.saveState()
        sessionManager.saveProgress()
    }

    // MARK: - Private Methods

    private func updateFromEngine() {
        let data = timerEngine.currentData
        currentMode = data.mode
        currentState = data.state
        displayTime = Self.formatTime(data.currentRemaining())
        updateButtonStates()
    }

    private func updateButtonStates() {
        isRunning = currentState == .running
        canStart = currentState.canStart || currentState.canResume
        canPause = currentState.canPause
        canReset = currentState.canReset
    }

    private static func formatTime(_ seconds: TimeInterval) -> String {
        return seconds.formatAsMMSS()
    }
}
