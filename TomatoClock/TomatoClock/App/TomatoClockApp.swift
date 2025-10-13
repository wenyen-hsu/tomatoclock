//
//  TomatoClockApp.swift
//  TomatoClock
//
//  Created on 2025-10-11
//

import SwiftUI

@main
struct TomatoClockApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // Service instances (shared throughout app)
    private let persistence: PersistenceServiceProtocol
    private let notificationService: NotificationServiceProtocol
    private let sessionManager: SessionManagerProtocol
    private let timerEngine: TimerEngineProtocol
    private let viewModel: TimerViewModel

    init() {
        // Initialize services
        let persistenceService = PersistenceService()
        let notificationSvc = NotificationService()
        let sessionMgr = SessionManager(persistence: persistenceService)
        let engine = TimerEngine(
            persistence: persistenceService,
            notifications: notificationSvc,
            sessionManager: sessionMgr
        )

        // Assign to properties
        persistence = persistenceService
        notificationService = notificationSvc
        sessionManager = sessionMgr
        timerEngine = engine

        // Initialize view model
        viewModel = TimerViewModel(
            timerEngine: engine,
            sessionManager: sessionMgr,
            notificationService: notificationSvc
        )

        // Request notification authorization (non-blocking)
        Task.detached {
            try? await notificationSvc.requestAuthorization()
        }
    }

    var body: some Scene {
        WindowGroup {
            TimerScreen(viewModel: viewModel)
        }
    }
}
