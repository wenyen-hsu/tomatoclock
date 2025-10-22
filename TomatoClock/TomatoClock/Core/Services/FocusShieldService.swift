//
//  FocusShieldService.swift
//  TomatoClock
//
//  Created on 2025-10-22
//

import Foundation
import Combine
import FamilyControls
import ManagedSettings

/// Service for managing app blocking during Focus sessions
/// This is a completely optional feature that doesn't affect core timer functionality
@available(iOS 15.0, *)
class FocusShieldService: ObservableObject {
    // MARK: - Singleton

    static let shared = FocusShieldService()

    // MARK: - Published Properties

    /// Whether the user has enabled Focus Shield
    @Published private(set) var isEnabled: Bool = false

    /// Current authorization status for Family Controls
    @Published private(set) var authorizationStatus: AuthorizationStatus = .notDetermined

    /// Whether shield is currently active (Focus is running with Shield enabled)
    @Published private(set) var isShieldActive: Bool = false

    // MARK: - Private Properties

    private let store = ManagedSettingsStore()
    private var cancellables = Set<AnyCancellable>()
    private var selectedApps: Set<ApplicationToken> = []

    private let enabledKey = "focusShieldEnabled"
    private let appsKey = "focusShieldSelectedApps"

    // MARK: - Initialization

    private init() {
        // Load enabled status from UserDefaults
        isEnabled = UserDefaults.standard.bool(forKey: enabledKey)

        // Monitor authorization status changes
        AuthorizationCenter.shared.$authorizationStatus
            .sink { [weak self] status in
                self?.authorizationStatus = status

                // If authorization is lost, disable the feature
                if status != .approved {
                    self?.setEnabled(false)
                }
            }
            .store(in: &cancellables)

        // Load selected apps
        loadSelectedApps()

        print("🛡️ [Focus Shield] Service initialized")
        print("   - Enabled: \(isEnabled)")
        print("   - Selected apps count: \(selectedApps.count)")
    }

    // MARK: - Public Methods - Authorization

    /// Request Family Controls authorization
    func requestAuthorization() async throws {
        print("🛡️ [Focus Shield] Requesting authorization...")

        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            print("✅ [Focus Shield] Authorization granted")
        } catch {
            print("❌ [Focus Shield] Authorization failed: \(error)")
            throw error
        }
    }

    // MARK: - Public Methods - Shield Control

    /// Enable shield (called when Focus starts)
    /// This method has zero cost if the feature is disabled or no apps are selected
    func enableShield() {
        // ⚠️ Critical: If feature is disabled or no apps selected, return immediately
        guard isEnabled, !selectedApps.isEmpty else {
            return
        }

        // ⚠️ Error handling: Even if this fails, don't affect the timer
        do {
            store.shield.applications = selectedApps
            isShieldActive = true
            print("✅ [Focus Shield] Enabled for \(selectedApps.count) apps")
        } catch {
            print("❌ [Focus Shield] Failed to enable: \(error)")
            // Don't throw - this is non-critical
        }
    }

    /// Disable shield (called when Focus ends, pauses, or resets)
    /// This method always attempts to disable to ensure consistent state
    func disableShield() {
        // ⚠️ Critical: Always try to disable, even if feature is off
        do {
            store.shield.applications = nil
            isShieldActive = false
            print("✅ [Focus Shield] Disabled")
        } catch {
            print("❌ [Focus Shield] Failed to disable: \(error)")
            // Don't throw - this is non-critical
        }
    }

    /// Immediately refresh shield state based on current selection
    /// Useful when user modifies the app list during an active session
    func refreshShield() {
        guard isEnabled, isShieldActive else {
            return
        }

        // Re-apply the current selection
        enableShield()
    }

    // MARK: - Public Methods - Sync

    /// Sync shield state with persisted timer state on app launch/foreground
    /// This ensures shield is correctly applied if app was terminated during Focus
    func syncShieldStateWithTimer() {
        // ⚠️ Critical: If feature is disabled, ensure shield is off and return
        guard isEnabled else {
            disableShield()
            return
        }

        // Load persisted timer data
        let persistence = PersistenceService()
        guard let timerData = persistence.loadTimerData() else {
            // No saved state, disable shield
            disableShield()
            print("🛡️ [Focus Shield] No saved timer state, shield disabled")
            return
        }

        // Check if timer should have shield active
        let shouldBeActive = timerData.mode == .focus && timerData.state == .running

        // Handle stale state (saved > 1 hour ago while running)
        if timerData.isStale {
            disableShield()
            print("🛡️ [Focus Shield] Stale timer state detected, shield disabled")
            return
        }

        // Sync shield state
        if shouldBeActive {
            enableShield()
            print("🛡️ [Focus Shield] Synced: Focus mode running, shield enabled")
        } else {
            disableShield()
            print("🛡️ [Focus Shield] Synced: Not in active Focus, shield disabled")
        }
    }

    // MARK: - Public Methods - Configuration

    /// Enable or disable the Focus Shield feature
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: enabledKey)

        print("🛡️ [Focus Shield] Feature \(enabled ? "enabled" : "disabled")")

        // If disabling, ensure shield is removed
        if !enabled {
            disableShield()
        }
    }

    /// Update the selected apps to block
    func setSelectedApps(_ selection: FamilyActivitySelection) {
        selectedApps = selection.applicationTokens
        saveSelectedApps()

        print("🛡️ [Focus Shield] Selected apps updated: \(selectedApps.count) apps")

        // If shield is currently active, refresh it
        refreshShield()
    }

    /// Get current app selection
    func getSelection() -> FamilyActivitySelection {
        var selection = FamilyActivitySelection()
        selection.applicationTokens = selectedApps
        return selection
    }

    /// Get the count of selected apps
    func getSelectedAppCount() -> Int {
        return selectedApps.count
    }

    // MARK: - Private Methods - Persistence

    private func loadSelectedApps() {
        guard let data = UserDefaults.standard.data(forKey: appsKey) else {
            selectedApps = []
            return
        }

        do {
            let decoder = JSONDecoder()
            selectedApps = try decoder.decode(Set<ApplicationToken>.self, from: data)
            print("✅ [Focus Shield] Loaded \(selectedApps.count) selected apps")
        } catch {
            print("❌ [Focus Shield] Failed to load selected apps: \(error)")
            selectedApps = []
        }
    }

    private func saveSelectedApps() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(selectedApps)
            UserDefaults.standard.set(data, forKey: appsKey)
            print("✅ [Focus Shield] Saved \(selectedApps.count) selected apps")
        } catch {
            print("❌ [Focus Shield] Failed to save selected apps: \(error)")
        }
    }
}
