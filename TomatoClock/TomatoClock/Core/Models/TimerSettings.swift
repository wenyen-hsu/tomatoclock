//
//  TimerSettings.swift
//  TomatoClock
//
//  Created on 2025-10-13
//

import Foundation

/// User-configurable timer settings including the repeating focus/rest flow.
struct TimerSettings: Codable, Equatable {
    var focusDuration: TimeInterval      // Legacy baseline focus duration (seconds)
    var shortBreakDuration: TimeInterval // Legacy baseline short break duration (seconds)
    var longBreakDuration: TimeInterval  // Legacy baseline long break duration (seconds)
    var autoRestMode: RestMode           // Legacy auto-rest selection (kept for compatibility)
    var flow: TimerFlowConfiguration     // New configurable flow sequence

    /// Default Pomodoro settings and flow.
    static let `default` = TimerSettings(
        focusDuration: 25 * 60,      // 25 minutes
        shortBreakDuration: 5 * 60,  // 5 minutes
        longBreakDuration: 15 * 60,  // 15 minutes
        autoRestMode: .shortBreak,
        flow: .default
    )

    init(
        focusDuration: TimeInterval,
        shortBreakDuration: TimeInterval,
        longBreakDuration: TimeInterval,
        autoRestMode: RestMode,
        flow: TimerFlowConfiguration
    ) {
        self.focusDuration = focusDuration
        self.shortBreakDuration = shortBreakDuration
        self.longBreakDuration = longBreakDuration
        self.autoRestMode = autoRestMode
        self.flow = flow
        alignBaseDurationsWithFlow()
    }

    /// Retrieve the configured duration for a given mode.
    func duration(for mode: TimerMode) -> TimeInterval {
        if let match = flow.steps.first(where: { $0.mode == mode }) {
            return match.duration
        }

        switch mode {
        case .focus:
            return focusDuration
        case .shortBreak:
            return shortBreakDuration
        case .longBreak:
            return longBreakDuration
        }
    }

    /// Validate that all configured durations stay within 1-60 minutes.
    var isValid: Bool {
        let minDuration: TimeInterval = 60      // 1 minute
        let maxDuration: TimeInterval = 60 * 60 // 60 minutes

        guard focusDuration >= minDuration && focusDuration <= maxDuration,
              shortBreakDuration >= minDuration && shortBreakDuration <= maxDuration,
              longBreakDuration >= minDuration && longBreakDuration <= maxDuration else {
            return false
        }

        return flow.durationsAreWithin(min: minDuration, max: maxDuration)
    }

    /// Make sure legacy baseline durations follow the current flow configuration for consistency.
    mutating func alignBaseDurationsWithFlow() {
        if let focusStep = flow.steps.first(where: { $0.mode == .focus }) {
            focusDuration = focusStep.duration
        }
        if let shortBreak = flow.steps.first(where: { $0.mode == .shortBreak }) {
            shortBreakDuration = shortBreak.duration
        }
        if let longBreak = flow.steps.first(where: { $0.mode == .longBreak }) {
            longBreakDuration = longBreak.duration
        }
    }
}

// MARK: - Codable

extension TimerSettings {
    private enum CodingKeys: String, CodingKey {
        case focusDuration
        case shortBreakDuration
        case longBreakDuration
        case autoRestMode
        case flow
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let decodedFocus = try container.decodeIfPresent(TimeInterval.self, forKey: .focusDuration) ?? 25 * 60
        let decodedShort = try container.decodeIfPresent(TimeInterval.self, forKey: .shortBreakDuration) ?? 5 * 60
        let decodedLong = try container.decodeIfPresent(TimeInterval.self, forKey: .longBreakDuration) ?? 15 * 60
        let decodedRestMode = try container.decodeIfPresent(RestMode.self, forKey: .autoRestMode) ?? .shortBreak
        let decodedFlow = try container.decodeIfPresent(TimerFlowConfiguration.self, forKey: .flow) ?? .default

        self.init(
            focusDuration: decodedFocus,
            shortBreakDuration: decodedShort,
            longBreakDuration: decodedLong,
            autoRestMode: decodedRestMode,
            flow: decodedFlow
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(focusDuration, forKey: .focusDuration)
        try container.encode(shortBreakDuration, forKey: .shortBreakDuration)
        try container.encode(longBreakDuration, forKey: .longBreakDuration)
        try container.encode(autoRestMode, forKey: .autoRestMode)
        try container.encode(flow, forKey: .flow)
    }
}
