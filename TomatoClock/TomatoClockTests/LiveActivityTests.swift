//
//  LiveActivityTests.swift
//  TomatoClockTests
//
//  Created on 2025-10-16
//

import Testing
import Foundation
@testable import TomatoClock

/// Unit tests for Live Activity data models and serialization
struct LiveActivityTests {

    // MARK: - TimerActivityAttributes.ContentState Tests

    @Test("ContentState serialization and deserialization") @MainActor
    func testContentStateEncodingDecoding() throws {
        // Given
        let original = TimerActivityAttributes.ContentState(
            remainingSeconds: 1500,
            totalDuration: 1500,
            mode: .focus,
            state: .running,
            displayTime: "25:00",
            timerEndDate: Date().addingTimeInterval(1500)
        )

        // When
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(
            TimerActivityAttributes.ContentState.self,
            from: data
        )

        // Then
        #expect(decoded.remainingSeconds == original.remainingSeconds)
        #expect(decoded.totalDuration == original.totalDuration)
        #expect(decoded.modeIdentifier == "focus")
        #expect(decoded.modeDisplayName == "Focus")
        #expect(decoded.modeLabel == "FOCUS TIME")
        #expect(decoded.stateIdentifier == "running")
        #expect(decoded.displayTime == original.displayTime)
    }

    @Test("ContentState convenience initializer with focus mode") @MainActor
    func testContentStateConvenienceInitializerFocus() {
        // Given
        let mode = TimerMode.focus
        let state = TimerState.running

        // When
        let contentState = TimerActivityAttributes.ContentState(
            remainingSeconds: 1500,
            totalDuration: 1500,
            mode: mode,
            state: state,
            displayTime: "25:00",
            timerEndDate: Date().addingTimeInterval(1500)
        )

        // Then
        #expect(contentState.modeIdentifier == "focus")
        #expect(contentState.modeDisplayName == "Focus")
        #expect(contentState.modeLabel == "FOCUS TIME")
        #expect(contentState.stateIdentifier == "running")
    }

    @Test("ContentState convenience initializer with short break mode") @MainActor
    func testContentStateConvenienceInitializerShortBreak() {
        // Given
        let mode = TimerMode.shortBreak
        let state = TimerState.paused

        // When
        let contentState = TimerActivityAttributes.ContentState(
            remainingSeconds: 300,
            totalDuration: 300,
            mode: mode,
            state: state,
            displayTime: "05:00",
            timerEndDate: Date().addingTimeInterval(300)
        )

        // Then
        #expect(contentState.modeIdentifier == "shortBreak")
        #expect(contentState.modeDisplayName == "Short Break")
        #expect(contentState.modeLabel == "BREAK TIME")
        #expect(contentState.stateIdentifier == "paused")
    }

    @Test("ContentState convenience initializer with long break mode") @MainActor
    func testContentStateConvenienceInitializerLongBreak() {
        // Given
        let mode = TimerMode.longBreak
        let state = TimerState.completed

        // When
        let contentState = TimerActivityAttributes.ContentState(
            remainingSeconds: 0,
            totalDuration: 900,
            mode: mode,
            state: state,
            displayTime: "00:00",
            timerEndDate: Date()
        )

        // Then
        #expect(contentState.modeIdentifier == "longBreak")
        #expect(contentState.modeDisplayName == "Long Break")
        #expect(contentState.modeLabel == "BREAK TIME")
        #expect(contentState.stateIdentifier == "completed")
    }

    // MARK: - Boundary Value Tests

    @Test("ContentState with zero remaining time") @MainActor
    func testContentStateZeroRemaining() {
        // Given & When
        let contentState = TimerActivityAttributes.ContentState(
            remainingSeconds: 0,
            totalDuration: 1500,
            mode: .focus,
            state: .completed,
            displayTime: "00:00",
            timerEndDate: Date()
        )

        // Then
        #expect(contentState.remainingSeconds == 0)
        #expect(contentState.totalDuration == 1500)
        #expect(contentState.stateIdentifier == "completed")
    }

    @Test("ContentState with negative time (edge case)") @MainActor
    func testContentStateNegativeTime() {
        // Given & When
        let contentState = TimerActivityAttributes.ContentState(
            remainingSeconds: -10,
            totalDuration: 1500,
            mode: .focus,
            state: .running,
            displayTime: "25:00",
            timerEndDate: Date().addingTimeInterval(-10)
        )

        // Then - Should not crash, just store the value
        #expect(contentState.remainingSeconds == -10)
    }

    @Test("ContentState with very long duration") @MainActor
    func testContentStateLongDuration() {
        // Given & When
        let longDuration: TimeInterval = 9999
        let contentState = TimerActivityAttributes.ContentState(
            remainingSeconds: longDuration,
            totalDuration: longDuration,
            mode: .focus,
            state: .running,
            displayTime: "166:39",
            timerEndDate: Date().addingTimeInterval(longDuration)
        )

        // Then
        #expect(contentState.remainingSeconds == 9999)
        #expect(contentState.totalDuration == 9999)
    }

    // MARK: - All Timer States Tests

    @Test("ContentState with ready state") @MainActor
    func testContentStateReadyState() {
        // Given & When
        let contentState = TimerActivityAttributes.ContentState(
            remainingSeconds: 1500,
            totalDuration: 1500,
            mode: .focus,
            state: .ready,
            displayTime: "25:00",
            timerEndDate: Date().addingTimeInterval(1500)
        )

        // Then
        #expect(contentState.stateIdentifier == "ready")
    }

    @Test("ContentState hashable conformance") @MainActor
    func testContentStateHashable() {
        // Given
        let date = Date()
        let contentState1 = TimerActivityAttributes.ContentState(
            remainingSeconds: 1500,
            totalDuration: 1500,
            mode: .focus,
            state: .running,
            displayTime: "25:00",
            timerEndDate: date
        )

        let contentState2 = TimerActivityAttributes.ContentState(
            remainingSeconds: 1500,
            totalDuration: 1500,
            mode: .focus,
            state: .running,
            displayTime: "25:00",
            timerEndDate: date
        )

        // Then - Same values should have same hash
        #expect(contentState1 == contentState2)
    }

    // MARK: - TimerActivityAttributes Tests

    @Test("TimerActivityAttributes creation")
    func testTimerActivityAttributesCreation() {
        // Given & When
        let attributes = TimerActivityAttributes(sessionCount: 3)

        // Then
        #expect(attributes.sessionCount == 3)
    }

    @Test("TimerActivityAttributes with zero session count")
    func testTimerActivityAttributesZeroSessions() {
        // Given & When
        let attributes = TimerActivityAttributes(sessionCount: 0)

        // Then
        #expect(attributes.sessionCount == 0)
    }
}
