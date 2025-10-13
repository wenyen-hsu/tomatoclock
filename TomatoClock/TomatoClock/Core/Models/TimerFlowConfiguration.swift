//
//  TimerFlowConfiguration.swift
//  TomatoClock
//
//  Created on 2025-10-19
//

import Foundation

/// Represents the full sequence of focus/rest cycles that repeat indefinitely.
struct TimerFlowConfiguration: Codable, Equatable {
    /// Ordered focus cycles that make up the flow.
    var cycles: [FocusCycleConfiguration]

    /// Default flow that mirrors the classic Pomodoro pattern.
    static let `default` = TimerFlowConfiguration(
        cycles: [
            FocusCycleConfiguration(
                focusDuration: 25 * 60,
                rest: RestConfiguration(mode: .shortBreak, duration: 5 * 60)
            ),
            FocusCycleConfiguration(
                focusDuration: 25 * 60,
                rest: RestConfiguration(mode: .longBreak, duration: 15 * 60)
            ),
            FocusCycleConfiguration(
                focusDuration: 25 * 60,
                rest: RestConfiguration(mode: .shortBreak, duration: 5 * 60)
            )
        ]
    )

    /// Flattened sequence steps derived from the cycles, used by the timer engine.
    var steps: [TimerSequenceStep] {
        cycles.flatMap { $0.sequenceSteps }
    }

    /// Ensure the flow never becomes empty by falling back to a single default cycle.
    mutating func ensureMinimumCycle() {
        if cycles.isEmpty {
            cycles = [FocusCycleConfiguration(
                focusDuration: 25 * 60,
                rest: RestConfiguration(mode: .shortBreak, duration: 5 * 60)
            )]
        }
    }

    /// Validate all contained durations against allowed bounds.
    /// - Parameters:
    ///   - min: Minimum allowed duration (seconds).
    ///   - max: Maximum allowed duration (seconds).
    /// - Returns: `true` when every focus and rest duration sits in range.
    func durationsAreWithin(min: TimeInterval, max: TimeInterval) -> Bool {
        guard !cycles.isEmpty else { return false }

        return cycles.allSatisfy { cycle in
            guard cycle.focusDuration >= min && cycle.focusDuration <= max else {
                return false
            }

            if let rest = cycle.rest {
                guard rest.duration >= min && rest.duration <= max else {
                    return false
                }
            }

            return true
        }
    }

    /// Update every cycle's durations to align with global baseline values.
    mutating func applyBaseDurations(
        focusDuration: TimeInterval,
        shortBreakDuration: TimeInterval,
        longBreakDuration: TimeInterval
    ) {
        for index in cycles.indices {
            cycles[index].focusDuration = focusDuration

            guard var rest = cycles[index].rest else { continue }

            switch rest.mode {
            case .shortBreak:
                rest.duration = shortBreakDuration
            case .longBreak:
                rest.duration = longBreakDuration
            case .focus:
                break
            }

            cycles[index].rest = rest
        }
    }
}

/// Single focus cycle consisting of one focus block and an optional subsequent rest block.
struct FocusCycleConfiguration: Codable, Identifiable, Equatable {
    let id: UUID
    var focusDuration: TimeInterval
    var rest: RestConfiguration?

    init(id: UUID = UUID(), focusDuration: TimeInterval, rest: RestConfiguration? = nil) {
        self.id = id
        self.focusDuration = focusDuration
        self.rest = rest
    }

    /// Sequence steps representing this cycle in the engine.
    var sequenceSteps: [TimerSequenceStep] {
        var steps: [TimerSequenceStep] = [
            TimerSequenceStep(
                id: id,
                kind: .focus,
                mode: .focus,
                duration: focusDuration,
                cycleId: id
            )
        ]

        if let rest {
            steps.append(rest.sequenceStep(for: id))
        }

        return steps
    }
}

/// Configuration for a rest block following a focus block.
struct RestConfiguration: Codable, Equatable {
    let id: UUID
    var mode: TimerMode
    var duration: TimeInterval

    init(id: UUID = UUID(), mode: TimerMode, duration: TimeInterval) {
        precondition(mode != .focus, "RestConfiguration cannot be created with focus mode")
        self.id = id
        self.mode = mode
        self.duration = duration
    }

    /// Build the step consumed by the engine.
    func sequenceStep(for cycleId: UUID) -> TimerSequenceStep {
        TimerSequenceStep(
            id: id,
            kind: .rest,
            mode: mode,
            duration: duration,
            cycleId: cycleId
        )
    }
}

/// Discrete step executed by the timer engine.
struct TimerSequenceStep: Codable, Equatable, Identifiable {
    enum Kind: String, Codable {
        case focus
        case rest
    }

    let id: UUID
    let kind: Kind
    let mode: TimerMode
    let duration: TimeInterval
    let cycleId: UUID
}
