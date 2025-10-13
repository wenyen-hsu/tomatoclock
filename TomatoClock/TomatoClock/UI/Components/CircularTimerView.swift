//
//  CircularTimerView.swift
//  TomatoClock
//
//  Created on 2025-10-11
//

import SwiftUI

/// Circular timer display with progress ring and time
struct CircularTimerView: View {
    let displayTime: String
    let modeLabel: String
    let progress: Double // 0.0 to 1.0

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let lineWidth: CGFloat = 8

            ZStack {
                // Background circle
                Circle()
                    .stroke(
                        Color("SecondaryGray"),
                        lineWidth: lineWidth
                    )

                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color("PrimaryRed"),
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.0), value: progress)

                // Center content
                VStack(spacing: 8) {
                    Text(displayTime)
                        .font(.system(size: size * 0.2, weight: .bold, design: .rounded))
                        .foregroundColor(Color("TextDark"))

                    Text(modeLabel)
                        .font(.system(size: size * 0.05, weight: .medium))
                        .foregroundColor(Color("SecondaryGray"))
                        .textCase(.uppercase)
                }
            }
            .frame(width: size, height: size)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        CircularTimerView(
            displayTime: "25:00",
            modeLabel: "FOCUS TIME",
            progress: 1.0
        )
        .frame(width: 300, height: 300)

        CircularTimerView(
            displayTime: "12:34",
            modeLabel: "FOCUS TIME",
            progress: 0.5
        )
        .frame(width: 300, height: 300)

        CircularTimerView(
            displayTime: "00:05",
            modeLabel: "BREAK TIME",
            progress: 0.1
        )
        .frame(width: 300, height: 300)
    }
    .padding()
}
