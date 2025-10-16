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
    @State private var showFlowEditor = false

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

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("自訂流程")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color("TextDark"))

                        Spacer()

                        Button(action: { showFlowEditor = true }) {
                            Text("編輯")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color("PrimaryRed"))
                        }
                    }

                    FlowTimelineView(
                        flow: viewModel.flowConfiguration,
                        activeStepID: viewModel.activeFlowStepID
                    )
                }
                .padding(16)
                .background(Color("SecondaryGray"))
                .cornerRadius(16)
                .padding(.horizontal, 20)

                Spacer()
                    .frame(height: 40)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel)
        }
        .sheet(isPresented: $showFlowEditor) {
            FlowEditorView(
                flow: viewModel.flowConfiguration,
                defaultFocusDuration: viewModel.timerEngine.timerSettings.focusDuration,
                defaultShortBreakDuration: viewModel.timerEngine.timerSettings.shortBreakDuration,
                defaultLongBreakDuration: viewModel.timerEngine.timerSettings.longBreakDuration,
                onSave: { newFlow in
                    viewModel.applyFlowConfiguration(newFlow)
                }
            )
        }
        .preferredColorScheme(.light)  // Force light mode to fix dark mode color issues
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
        let totalSeconds = viewModel.timerEngine.currentData.totalDuration
        guard totalSeconds > 0 else { return 1.0 }

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
