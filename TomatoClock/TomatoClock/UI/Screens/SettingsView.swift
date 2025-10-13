//
//  SettingsView.swift
//  TomatoClock
//
//  Created on 2025-10-13
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TimerViewModel

    @State private var focusMinutes: Int
    @State private var shortBreakMinutes: Int
    @State private var longBreakMinutes: Int

    private let minuteOptions = Array(1...60)

    init(viewModel: TimerViewModel) {
        self.viewModel = viewModel
        let settings = viewModel.timerEngine.timerSettings
        _focusMinutes = State(initialValue: Int(settings.focusDuration / 60))
        _shortBreakMinutes = State(initialValue: Int(settings.shortBreakDuration / 60))
        _longBreakMinutes = State(initialValue: Int(settings.longBreakDuration / 60))
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("計時器時長設定")) {
                    HStack {
                        Text("專注時間")
                        Spacer()
                        Picker("", selection: $focusMinutes) {
                            ForEach(minuteOptions, id: \.self) { minute in
                                Text("\(minute) 分鐘").tag(minute)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    HStack {
                        Text("短休息時間")
                        Spacer()
                        Picker("", selection: $shortBreakMinutes) {
                            ForEach(minuteOptions, id: \.self) { minute in
                                Text("\(minute) 分鐘").tag(minute)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    HStack {
                        Text("長休息時間")
                        Spacer()
                        Picker("", selection: $longBreakMinutes) {
                            ForEach(minuteOptions, id: \.self) { minute in
                                Text("\(minute) 分鐘").tag(minute)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section {
                    Button(action: saveSettings) {
                        HStack {
                            Spacer()
                            Text("保存設定")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .foregroundColor(.white)
                    .listRowBackground(Color("PrimaryRed"))
                }

                Section(header: Text("說明")) {
                    Text("修改後的時間將在下次計時器重置時生效")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveSettings() {
        let focusSeconds = TimeInterval(focusMinutes * 60)
        let shortBreakSeconds = TimeInterval(shortBreakMinutes * 60)
        let longBreakSeconds = TimeInterval(longBreakMinutes * 60)

        var updatedFlow = viewModel.timerEngine.timerSettings.flow
        updatedFlow.applyBaseDurations(
            focusDuration: focusSeconds,
            shortBreakDuration: shortBreakSeconds,
            longBreakDuration: longBreakSeconds
        )

        let newSettings = TimerSettings(
            focusDuration: focusSeconds,
            shortBreakDuration: shortBreakSeconds,
            longBreakDuration: longBreakSeconds,
            autoRestMode: viewModel.timerEngine.timerSettings.autoRestMode,
            flow: updatedFlow
        )

        viewModel.updateTimerSettings(newSettings)
        dismiss()
    }
}
