//
//  PersistenceService.swift
//  TomatoClock
//
//  Created on 2025-10-11
//

import Foundation

/// Protocol for persistence operations
protocol PersistenceServiceProtocol {
    func saveTimerData(_ data: TimerData) throws
    func loadTimerData() -> TimerData?
    func saveSessionProgress(_ progress: SessionProgress) throws
    func loadSessionProgress() -> SessionProgress?
    func saveTimerSettings(_ settings: TimerSettings) throws
    func loadTimerSettings() -> TimerSettings?
    func clearAll()
}

/// UserDefaults-based persistence service
class PersistenceService: PersistenceServiceProtocol {
    private enum Keys {
        static let timerData = "com.tomatoclock.timer.data"
        static let sessionProgress = "com.tomatoclock.session.progress"
        static let timerSettings = "com.tomatoclock.timer.settings"
    }

    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Timer Data

    func saveTimerData(_ data: TimerData) throws {
        do {
            let encoded = try encoder.encode(data)
            userDefaults.set(encoded, forKey: Keys.timerData)
            userDefaults.synchronize()
        } catch {
            throw TimerError.persistenceFailure(underlyingError: error)
        }
    }

    func loadTimerData() -> TimerData? {
        guard let data = userDefaults.data(forKey: Keys.timerData) else {
            return nil
        }

        do {
            return try decoder.decode(TimerData.self, from: data)
        } catch {
            print("⚠️ Failed to decode TimerData: \(error). Using default.")
            return nil
        }
    }

    // MARK: - Session Progress

    func saveSessionProgress(_ progress: SessionProgress) throws {
        do {
            let encoded = try encoder.encode(progress)
            userDefaults.set(encoded, forKey: Keys.sessionProgress)
            userDefaults.synchronize()
        } catch {
            throw TimerError.persistenceFailure(underlyingError: error)
        }
    }

    func loadSessionProgress() -> SessionProgress? {
        guard let data = userDefaults.data(forKey: Keys.sessionProgress) else {
            return nil
        }

        do {
            return try decoder.decode(SessionProgress.self, from: data)
        } catch {
            print("⚠️ Failed to decode SessionProgress: \(error). Using default.")
            return nil
        }
    }

    // MARK: - Timer Settings

    func saveTimerSettings(_ settings: TimerSettings) throws {
        do {
            let encoded = try encoder.encode(settings)
            userDefaults.set(encoded, forKey: Keys.timerSettings)
            userDefaults.synchronize()
        } catch {
            throw TimerError.persistenceFailure(underlyingError: error)
        }
    }

    func loadTimerSettings() -> TimerSettings? {
        guard let data = userDefaults.data(forKey: Keys.timerSettings) else {
            return nil
        }

        do {
            return try decoder.decode(TimerSettings.self, from: data)
        } catch {
            print("⚠️ Failed to decode TimerSettings: \(error). Using default.")
            return nil
        }
    }

    // MARK: - Utilities

    func clearAll() {
        userDefaults.removeObject(forKey: Keys.timerData)
        userDefaults.removeObject(forKey: Keys.sessionProgress)
        userDefaults.removeObject(forKey: Keys.timerSettings)
        userDefaults.synchronize()
    }
}
