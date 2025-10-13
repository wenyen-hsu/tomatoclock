//
//  SessionManager.swift
//  TomatoClock
//
//  Created on 2025-10-11
//

import Foundation
import Combine

/// Manages session tracking, 4-cycle logic, and daily reset
class SessionManager: SessionManagerProtocol {
    // MARK: - Properties

    private(set) var currentProgress: SessionProgress

    private let progressSubject = PassthroughSubject<SessionProgress, Never>()

    var progressPublisher: AnyPublisher<SessionProgress, Never> {
        progressSubject.eraseToAnyPublisher()
    }

    private let persistence: PersistenceServiceProtocol

    // MARK: - Initialization

    init(persistence: PersistenceServiceProtocol) {
        self.persistence = persistence
        self.currentProgress = .default
        loadProgress()
        checkAndResetIfNewDay()
    }

    // MARK: - Session Management

    @discardableResult
    func recordCompletedSession() -> SessionProgress {
        // Increment session count
        currentProgress = currentProgress.incrementSession()

        // Save progress
        saveProgress()

        // Publish change
        progressSubject.send(currentProgress)

        return currentProgress
    }

    func recommendedNextMode() -> TimerMode {
        // After 4th session (position 3), recommend long break
        // Otherwise recommend short break
        return currentProgress.shouldTriggerLongBreak ? .longBreak : .shortBreak
    }

    @discardableResult
    func checkAndResetIfNewDay() -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let lastResetDay = Calendar.current.startOfDay(for: currentProgress.lastResetDate)

        // Check if we're on a new day
        if !Calendar.current.isDate(today, inSameDayAs: lastResetDay) {
            // Reset progress for new day
            currentProgress = SessionProgress(
                completedCount: 0,
                lastResetDate: today
            )

            // Save reset progress
            saveProgress()

            // Publish change
            progressSubject.send(currentProgress)

            return true
        }

        return false
    }

    // MARK: - Persistence

    func loadProgress() {
        if let loaded = persistence.loadSessionProgress() {
            currentProgress = loaded.checkAndReset()

            // If reset occurred during load, save the reset state
            if loaded.completedCount != currentProgress.completedCount {
                saveProgress()
            }
        }
    }

    func saveProgress() {
        do {
            try persistence.saveSessionProgress(currentProgress)
        } catch {
            // Log error but don't crash
            print("Failed to save session progress: \(error)")
        }
    }
}
