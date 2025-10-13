//
//  FlowTimelineView.swift
//  TomatoClock
//
//  Created on 2025-10-19
//

import SwiftUI

struct FlowTimelineView: View {
    let flow: TimerFlowConfiguration
    let activeStepID: UUID?

    private var steps: [TimerSequenceStep] { flow.steps }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: 12) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    FlowTimelineBlock(step: step, isActive: step.id == activeStepID)

                    if index < steps.count - 1 {
                        Image(systemName: "chevron.compact.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color("TextDark").opacity(0.4))
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

private struct FlowTimelineBlock: View {
    let step: TimerSequenceStep
    let isActive: Bool

    private var backgroundColor: Color {
        switch step.kind {
        case .focus:
            return Color("PrimaryRed")
        case .rest:
            return Color.blue.opacity(0.18)
        }
    }

    private var foregroundColor: Color {
        switch step.kind {
        case .focus:
            return .white
        case .rest:
            return Color("TextDark")
        }
    }

    private var borderColor: Color {
        isActive ? Color.blue : Color.clear
    }

    private var title: String {
        switch step.kind {
        case .focus:
            return "專注"
        case .rest:
            switch step.mode {
            case .shortBreak:
                return "短休息"
            case .longBreak:
                return "長休息"
            default:
                return "休息"
            }
        }
    }

    private var durationText: String {
        let minutes = Int(round(step.duration / 60))
        return "\(minutes) 分鐘"
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(foregroundColor)

            Text(durationText)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(foregroundColor.opacity(0.85))
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(backgroundColor)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: isActive ? 2 : 0)
        )
        .shadow(color: Color.black.opacity(isActive ? 0.2 : 0.08), radius: isActive ? 8 : 4, x: 0, y: 3)
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}

#Preview {
    FlowTimelineView(
        flow: TimerFlowConfiguration.default,
        activeStepID: TimerFlowConfiguration.default.steps.first?.id
    )
    .padding()
    .background(Color("BackgroundWhite"))
}
