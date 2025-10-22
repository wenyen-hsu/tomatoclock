//
//  FocusShieldSettingsView.swift
//  TomatoClock
//
//  Created on 2025-10-22
//

import SwiftUI
import FamilyControls

/// Settings view for Focus Shield feature
/// This is a completely optional feature that doesn't affect core timer functionality
@available(iOS 15.0, *)
struct FocusShieldSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var shieldService = FocusShieldService.shared
    @State private var showingAppPicker = false
    @State private var showingAuthorizationAlert = false
    @State private var authorizationError: Error?
    @State private var selection = FamilyActivitySelection()

    var body: some View {
        Form {
            // Enable/Disable Section
            Section {
                Toggle("啟用專注防護", isOn: Binding(
                    get: { shieldService.isEnabled },
                    set: { newValue in
                        if newValue {
                            requestAuthorizationIfNeeded()
                        } else {
                            shieldService.setEnabled(false)
                        }
                    }
                ))
            } header: {
                Text("專注防護")
            } footer: {
                Text("啟用後，在專注時間會自動屏蔽選擇的 App，休息時間自動解除屏蔽")
                    .font(.caption)
            }

            // App Selection Section
            if shieldService.isEnabled {
                Section {
                    Button(action: {
                        selection = shieldService.getSelection()
                        showingAppPicker = true
                    }) {
                        HStack {
                            Text("選擇要屏蔽的 App")
                            Spacer()
                            let count = shieldService.getSelectedAppCount()
                            Text(count == 0 ? "未選擇" : "\(count) 個 App")
                                .foregroundColor(.gray)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                } header: {
                    Text("屏蔽設定")
                } footer: {
                    Text("選擇在專注時間想要屏蔽的 App，例如社交媒體、遊戲等")
                        .font(.caption)
                }
            }

            // Current Status Section
            Section {
                HStack {
                    Text("當前狀態")
                    Spacer()
                    Label(
                        shieldService.isShieldActive ? "已啟用 🛡️" : "未啟用",
                        systemImage: shieldService.isShieldActive ? "shield.fill" : "shield"
                    )
                    .foregroundColor(shieldService.isShieldActive ? .green : .gray)
                }
            } header: {
                Text("狀態")
            } footer: {
                if shieldService.isShieldActive {
                    Text("專注防護正在運行中，選擇的 App 已被屏蔽")
                        .font(.caption)
                } else if shieldService.isEnabled {
                    Text("專注防護已就緒，將在下次專注時間自動啟用")
                        .font(.caption)
                } else {
                    Text("專注防護未啟用")
                        .font(.caption)
                }
            }

            // How it works Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("專注時間自動屏蔽", systemImage: "hourglass")
                    Label("休息時間自動解除", systemImage: "cup.and.saucer")
                    Label("可隨時調整清單", systemImage: "slider.horizontal.3")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            } header: {
                Text("運作方式")
            }

            // Requirements Section
            Section {
                HStack {
                    Image(systemName: "exclamationmark.shield")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("需要螢幕使用時間權限")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("首次啟用時會請求權限")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .navigationTitle("專注防護")
        .navigationBarTitleDisplayMode(.inline)
        .familyActivityPicker(
            isPresented: $showingAppPicker,
            selection: $selection
        )
        .onChange(of: selection) { newSelection in
            shieldService.setSelectedApps(newSelection)
        }
        .alert("需要授權", isPresented: $showingAuthorizationAlert) {
            Button("前往設定", role: .none) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("取消", role: .cancel) {
                shieldService.setEnabled(false)
            }
        } message: {
            if let error = authorizationError {
                Text("無法啟用專注防護：\(error.localizedDescription)\n\n請在設定中授予「螢幕使用時間」權限")
            } else {
                Text("TomatoClock 需要「螢幕使用時間」權限才能在專注時間屏蔽 App")
            }
        }
    }

    private func requestAuthorizationIfNeeded() {
        // Check current status
        switch shieldService.authorizationStatus {
        case .approved:
            // Already authorized, enable directly
            shieldService.setEnabled(true)
        case .notDetermined:
            // Request authorization
            Task {
                do {
                    try await shieldService.requestAuthorization()
                    await MainActor.run {
                        shieldService.setEnabled(true)
                    }
                } catch {
                    await MainActor.run {
                        authorizationError = error
                        showingAuthorizationAlert = true
                    }
                }
            }
        case .denied:
            // Show alert to go to Settings
            authorizationError = nil
            showingAuthorizationAlert = true
        @unknown default:
            break
        }
    }
}

/// Preview for Focus Shield Settings
@available(iOS 15.0, *)
struct FocusShieldSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FocusShieldSettingsView()
        }
    }
}
