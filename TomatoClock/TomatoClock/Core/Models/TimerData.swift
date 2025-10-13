//
//  TimerData.swift
//  TomatoClock
//
//  Created on 2025-10-11
//

import Foundation

/// Complete snapshot of timer state for persistence and restoration
struct TimerData: Codable {
    /// Current timer mode (focus/shortBreak/longBreak)
    let mode: TimerMode

    /// Current lifecycle state (ready/running/paused/completed)
    let state: TimerState

    /// Remaining time in seconds (0 to totalDuration)
    let remainingSeconds: TimeInterval

    /// Configured total duration for the session (used instead of TimerMode defaults)
    let totalDuration: TimeInterval

    /// Monotonic start time (ProcessInfo.systemUptime) when timer started
    /// nil if state is ready or paused
    let startUptime: TimeInterval?

    /// Accumulated elapsed time before current run
    /// Used for pause/resume: total = elapsedBeforeStart + (now - startUptime)
    let elapsedBeforeStart: TimeInterval

    /// Timestamp when this state was saved (for staleness detection)
    let savedAt: Date

    /// Index of the current step inside the repeating custom flow.
    let sequenceIndex: Int

    /// Default state: Focus mode, ready, 25:00 remaining
    static var `default`: TimerData {
        return TimerData(
            mode: .focus,
            state: .ready,
            remainingSeconds: 25 * 60,
            totalDuration: 25 * 60,
            startUptime: nil,
            elapsedBeforeStart: 0,
            savedAt: Date(),
            sequenceIndex: 0
        )
    }
}

extension TimerData {
    private enum CodingKeys: String, CodingKey {
        case mode
        case state
        case remainingSeconds
        case totalDuration
        case startUptime
        case elapsedBeforeStart
        case savedAt
        case sequenceIndex
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        mode = try container.decode(TimerMode.self, forKey: .mode)
        state = try container.decode(TimerState.self, forKey: .state)
        remainingSeconds = try container.decode(TimeInterval.self, forKey: .remainingSeconds)
        totalDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .totalDuration)
            ?? max(remainingSeconds, mode.duration)
        startUptime = try container.decodeIfPresent(TimeInterval.self, forKey: .startUptime)
        elapsedBeforeStart = try container.decode(TimeInterval.self, forKey: .elapsedBeforeStart)
        savedAt = try container.decode(Date.self, forKey: .savedAt)
        sequenceIndex = try container.decodeIfPresent(Int.self, forKey: .sequenceIndex) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(mode, forKey: .mode)
        try container.encode(state, forKey: .state)
        try container.encode(remainingSeconds, forKey: .remainingSeconds)
        try container.encode(totalDuration, forKey: .totalDuration)
        try container.encodeIfPresent(startUptime, forKey: .startUptime)
        try container.encode(elapsedBeforeStart, forKey: .elapsedBeforeStart)
        try container.encode(savedAt, forKey: .savedAt)
        try container.encode(sequenceIndex, forKey: .sequenceIndex)
    }

    /// Current elapsed time (considering running state)
    func currentElapsed() -> TimeInterval {
        guard let start = startUptime, state == .running else {
            return elapsedBeforeStart
        }
        let now = ProcessInfo.processInfo.systemUptime
        return elapsedBeforeStart + (now - start)
    }

    /// Current remaining time (considering running state)
    func currentRemaining() -> TimeInterval {
        return max(0, totalDuration - currentElapsed())
    }

    /// Is this saved state stale? (saved > 1 hour ago while running)
    var isStale: Bool {
        return state == .running && Date().timeIntervalSince(savedAt) > 3600
    }
}
