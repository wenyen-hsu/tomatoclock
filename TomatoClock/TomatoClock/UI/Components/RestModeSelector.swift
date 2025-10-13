//
//  RestModeSelector.swift
//  TomatoClock
//
//  Created on 2025-10-13
//

import SwiftUI

struct RestModeSelector: View {
    let currentMode: RestMode
    let onModeChanged: (RestMode) -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("完成後")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color("TextDark").opacity(0.6))

            HStack(spacing: 12) {
                ForEach(RestMode.allCases, id: \.self) { mode in
                    RestModeButton(
                        mode: mode,
                        isSelected: currentMode == mode,
                        onTap: { onModeChanged(mode) }
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color("SecondaryGray"))
        .cornerRadius(16)
    }
}

struct RestModeButton: View {
    let mode: RestMode
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : Color("TextDark"))

                Text(mode.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color("TextDark"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color("PrimaryRed") : Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(isSelected ? 0.15 : 0.05), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        RestModeSelector(currentMode: .shortBreak) { mode in
            print("Selected: \(mode)")
        }

        RestModeSelector(currentMode: .none) { mode in
            print("Selected: \(mode)")
        }
    }
    .padding()
    .background(Color("BackgroundWhite"))
}
