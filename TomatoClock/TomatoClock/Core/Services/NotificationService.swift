//
//  NotificationService.swift
//  TomatoClock
//
//  Created on 2025-10-11
//

import Foundation
import UserNotifications
import Combine

/// Service for scheduling and managing local notifications
class NotificationService: NotificationServiceProtocol {
    // MARK: - Properties

    private let notificationCenter: UNUserNotificationCenter
    private let statusSubject = CurrentValueSubject<UNAuthorizationStatus, Never>(.notDetermined)

    var authorizationStatus: AnyPublisher<UNAuthorizationStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    init(notificationCenter: UNUserNotificationCenter = UNUserNotificationCenter.current()) {
        self.notificationCenter = notificationCenter
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func requestAuthorization() async throws -> Bool {
        let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])

        let settings = await notificationCenter.notificationSettings()
        statusSubject.send(settings.authorizationStatus)

        return granted
    }

    // MARK: - Scheduling

    func scheduleCompletionNotification(
        for mode: TimerMode,
        at fireDate: Date,
        identifier: String
    ) throws {
        // Create notification content
        let content = UNMutableNotificationContent()

        switch mode {
        case .focus:
            content.title = "Focus Complete!"
            content.body = "Great work! Time for a 5-minute break."

        case .shortBreak:
            content.title = "Break Complete!"
            content.body = "Ready to focus again?"

        case .longBreak:
            content.title = "Long Break Complete!"
            content.body = "Ready for another Pomodoro session?"
        }

        content.sound = .default
        content.badge = 1

        // Calculate time interval
        let timeInterval = fireDate.timeIntervalSinceNow
        guard timeInterval > 0 else {
            throw TimerError.notificationSchedulingFailed(
                underlyingError: NSError(
                    domain: "com.tomatoclock.notifications",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Fire date is in the past"]
                )
            )
        }

        // Create trigger
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )

        // Create request
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        // Schedule notification
        Task {
            do {
                try await notificationCenter.add(request)
            } catch {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    // MARK: - Cancellation

    func cancelNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    // MARK: - Private Methods

    private func checkAuthorizationStatus() {
        Task {
            let settings = await notificationCenter.notificationSettings()
            statusSubject.send(settings.authorizationStatus)
        }
    }
}
