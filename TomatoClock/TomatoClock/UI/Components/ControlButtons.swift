//
//  ControlButtons.swift
//  TomatoClock
//
//  Created on 2025-10-11
//

import SwiftUI

/// Control buttons for timer (play/pause, reset)
struct ControlButtons: View {
    let isRunning: Bool
    let canStart: Bool
    let canPause: Bool
    let canReset: Bool

    let onPlayPauseTapped: () -> Void
    let onResetTapped: () -> Void

    private let buttonSize: CGFloat = 72

    var body: some View {
        HStack(spacing: 24) {
            // Reset button
            Button(action: onResetTapped) {
                ZStack {
                    Circle()
                        .fill(Color("SecondaryGray"))
                        .frame(width: buttonSize * 0.75, height: buttonSize * 0.75)

                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(Color("TextDark"))
                }
            }
            .disabled(!canReset)
            .opacity(canReset ? 1.0 : 0.5)

            // Play/Pause button
            Button(action: onPlayPauseTapped) {
                ZStack {
                    Circle()
                        .fill(Color("PrimaryRed"))
                        .frame(width: buttonSize, height: buttonSize)
                        .shadow(color: Color("PrimaryRed").opacity(0.3), radius: 8, x: 0, y: 4)

                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: isRunning ? 0 : 3) // Align play icon better
                }
            }
            .disabled(!canStart && !canPause)
            .opacity((canStart || canPause) ? 1.0 : 0.5)

            // Placeholder for future button (skip/next)
            Circle()
                .fill(Color.clear)
                .frame(width: buttonSize * 0.75, height: buttonSize * 0.75)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        // Ready state
        ControlButtons(
            isRunning: false,
            canStart: true,
            canPause: false,
            canReset: false,
            onPlayPauseTapped: {},
            onResetTapped: {}
        )

        // Running state
        ControlButtons(
            isRunning: true,
            canStart: false,
            canPause: true,
            canReset: true,
            onPlayPauseTapped: {},
            onResetTapped: {}
        )

        // Paused state
        ControlButtons(
            isRunning: false,
            canStart: true,
            canPause: false,
            canReset: true,
            onPlayPauseTapped: {},
            onResetTapped: {}
        )
    }
    .padding()
}
