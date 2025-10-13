//
//  TimerScreen.swift
//  TomatoClock
//
//  Created on 2025-10-11
//

import SwiftUI

/// Main timer screen composing all UI components
struct TimerScreen: View {
    @StateObject private var viewModel: TimerViewModel
    @State private var showSettings = false

    init(viewModel: TimerViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            // Background
            Color("BackgroundWhite")
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Header with settings button
                ZStack {
                    AppHeader()

                    HStack {
                        Spacer()
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color("PrimaryRed"))
                        }
                        .padding(.trailing, 20)
                    }
                }
                .padding(.top, 40)

                Spacer()

                // Main timer display
                CircularTimerView(
                    displayTime: viewModel.displayTime,
                    modeLabel: viewModel.currentMode.label,
                    progress: calculateProgress()
                )
                .frame(height: 300)
                .padding(.horizontal, 40)

                Spacer()

                // Control buttons
                ControlButtons(
                    isRunning: viewModel.isRunning,
                    canStart: viewModel.canStart,
                    canPause: viewModel.canPause,
                    canReset: viewModel.canReset,
                    onPlayPauseTapped: {
                        if viewModel.isRunning {
                            viewModel.pauseTapped()
                        } else {
                            viewModel.startTapped()
                        }
                    },
                    onResetTapped: {
                        viewModel.resetTapped()
                    }
                )
                .padding(.bottom, 20)

                // Rest mode selector (always available for upcoming rest)
                RestModeSelector(
                    currentMode: viewModel.timerEngine.timerSettings.autoRestMode
                ) { mode in
                    viewModel.updateRestMode(mode)
                }
                .padding(.horizontal, 20)

                Spacer()
                    .frame(height: 40)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.setup()
        }
        .onDisappear {
            viewModel.saveState()
        }
    }

    // MARK: - Private Methods

    private func calculateProgress() -> Double {
        // Parse display time "MM:SS" to seconds
        let components = viewModel.displayTime.split(separator: ":")
        guard components.count == 2,
              let minutes = Int(components[0]),
              let seconds = Int(components[1]) else {
            return 1.0
        }

        let remainingSeconds = TimeInterval(minutes * 60 + seconds)
        let totalSeconds = viewModel.timerEngine.timerSettings.duration(for: viewModel.currentMode)

        // Progress is how much time has elapsed (1.0 = full, 0.0 = empty)
        return remainingSeconds / totalSeconds
    }
}

// MARK: - Preview

#Preview {
    let testDefaults = UserDefaults(suiteName: "preview")!
    let persistence = PersistenceService(userDefaults: testDefaults)
    let notifications = NotificationService()
    let sessionManager = SessionManager(persistence: persistence)
    let engine = TimerEngine(
        persistence: persistence,
        notifications: notifications,
        sessionManager: sessionManager
    )
    let viewModel = TimerViewModel(
        timerEngine: engine,
        sessionManager: sessionManager,
        notificationService: notifications
    )

    return TimerScreen(viewModel: viewModel)
}
