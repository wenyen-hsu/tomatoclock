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
                do {
                    let granted = try await UNUserNotificationCenter.current()
                        .requestAuthorization(options: [.alert, .sound, .badge])
                    if !granted {
                        print("Notification authorization denied by user")
                    }
                } catch {
                    print("Failed to request notification authorization: \(error)")
                }
            }
        }

        // ✅ Focus Shield: Sync shield state with persisted timer on app launch
        if #available(iOS 15.0, *) {
            FocusShieldService.shared.syncShieldStateWithTimer()
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

        // ✅ Focus Shield: Sync shield state when returning from background
        if #available(iOS 15.0, *) {
            FocusShieldService.shared.syncShieldStateWithTimer()
        }
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
