//
//  AppDelegate.swift
//  TomatoClock
//
//  Created on 2025-10-11
//

import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Setup notification delegate
        UNUserNotificationCenter.current().delegate = self

        // Request notification authorization if not already determined
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            if settings.authorizationStatus == .notDetermined {
                try? await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound, .badge])
            }
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Save state when app goes to background
        NotificationCenter.default.post(name: .willResignActive, object: nil)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Additional background handling if needed
        print("App entered background")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Refresh state when returning to foreground
        print("App entering foreground")
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap - open app
        print("Notification tapped: \(response.notification.request.identifier)")
        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let willResignActive = Notification.Name("willResignActive")
}
