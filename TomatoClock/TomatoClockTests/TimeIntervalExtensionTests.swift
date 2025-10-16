//
//  TimeIntervalExtensionTests.swift
//  TomatoClockTests
//
//  Created on 2025-10-16
//

import Testing
import Foundation
@testable import TomatoClock

/// Unit tests for TimeInterval extension methods
struct TimeIntervalExtensionTests {

    // MARK: - formatAsMMSS Tests

    @Test("Format 0 seconds as MM:SS")
    func testFormatZeroSeconds() {
        // Given
        let interval: TimeInterval = 0

        // When
        let formatted = interval.formatAsMMSS()

        // Then
        #expect(formatted == "00:00")
    }

    @Test("Format 59 seconds as MM:SS")
    func testFormat59Seconds() {
        // Given
        let interval: TimeInterval = 59

        // When
        let formatted = interval.formatAsMMSS()

        // Then
        #expect(formatted == "00:59")
    }

    @Test("Format 60 seconds (1 minute) as MM:SS")
    func testFormat60Seconds() {
        // Given
        let interval: TimeInterval = 60

        // When
        let formatted = interval.formatAsMMSS()

        // Then
        #expect(formatted == "01:00")
    }

    @Test("Format 1500 seconds (25 minutes) as MM:SS")
    func testFormat1500Seconds() {
        // Given
        let interval: TimeInterval = 1500

        // When
        let formatted = interval.formatAsMMSS()

        // Then
        #expect(formatted == "25:00")
    }

    @Test("Format 300 seconds (5 minutes) as MM:SS")
    func testFormat300Seconds() {
        // Given
        let interval: TimeInterval = 300

        // When
        let formatted = interval.formatAsMMSS()

        // Then
        #expect(formatted == "05:00")
    }

    @Test("Format 900 seconds (15 minutes) as MM:SS")
    func testFormat900Seconds() {
        // Given
        let interval: TimeInterval = 900

        // When
        let formatted = interval.formatAsMMSS()

        // Then
        #expect(formatted == "15:00")
    }

    @Test("Format 3661 seconds (1 hour 1 minute 1 second) as MM:SS")
    func testFormat3661Seconds() {
        // Given
        let interval: TimeInterval = 3661

        // When
        let formatted = interval.formatAsMMSS()

        // Then
        #expect(formatted == "61:01")
    }

    @Test("Format 1 second as MM:SS")
    func testFormat1Second() {
        // Given
        let interval: TimeInterval = 1

        // When
        let formatted = interval.formatAsMMSS()

        // Then
        #expect(formatted == "00:01")
    }

    @Test("Format 125 seconds (2 minutes 5 seconds) as MM:SS")
    func testFormat125Seconds() {
        // Given
        let interval: TimeInterval = 125

        // When
        let formatted = interval.formatAsMMSS()

        // Then
        #expect(formatted == "02:05")
    }

    @Test("Format fractional seconds truncates to integer")
    func testFormatFractionalSeconds() {
        // Given
        let interval: TimeInterval = 65.7

        // When
        let formatted = interval.formatAsMMSS()

        // Then
        #expect(formatted == "01:05") // Should truncate to 65 seconds
    }

    @Test("Format negative time (edge case)")
    func testFormatNegativeTime() {
        // Given
        let interval: TimeInterval = -10

        // When
        let formatted = interval.formatAsMMSS()

        // Then - Should handle gracefully (implementation dependent)
        #expect(formatted.contains(":"))
    }

    @Test("Format very large duration")
    func testFormatVeryLargeDuration() {
        // Given
        let interval: TimeInterval = 9999

        // When
        let formatted = interval.formatAsMMSS()

        // Then
        #expect(formatted == "166:39") // 9999 seconds = 166 minutes 39 seconds
    }

    @Test("Format with decimal precision")
    func testFormatDecimalPrecision() {
        // Given
        let intervals: [TimeInterval] = [
            1.1,  // Should be 00:01
            1.5,  // Should be 00:01
            1.9,  // Should be 00:01
            2.0   // Should be 00:02
        ]

        // When & Then
        #expect(intervals[0].formatAsMMSS() == "00:01")
        #expect(intervals[1].formatAsMMSS() == "00:01")
        #expect(intervals[2].formatAsMMSS() == "00:01")
        #expect(intervals[3].formatAsMMSS() == "00:02")
    }

    // MARK: - Common Timer Durations Tests

    @Test("Format focus duration (25 minutes)")
    func testFormatFocusDuration() {
        // Given
        let focusDuration: TimeInterval = 25 * 60

        // When
        let formatted = focusDuration.formatAsMMSS()

        // Then
        #expect(formatted == "25:00")
    }

    @Test("Format short break duration (5 minutes)")
    func testFormatShortBreakDuration() {
        // Given
        let shortBreakDuration: TimeInterval = 5 * 60

        // When
        let formatted = shortBreakDuration.formatAsMMSS()

        // Then
        #expect(formatted == "05:00")
    }

    @Test("Format long break duration (15 minutes)")
    func testFormatLongBreakDuration() {
        // Given
        let longBreakDuration: TimeInterval = 15 * 60

        // When
        let formatted = longBreakDuration.formatAsMMSS()

        // Then
        #expect(formatted == "15:00")
    }
}
