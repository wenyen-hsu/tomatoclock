//
//  AppHeader.swift
//  TomatoClock
//
//  Created on 2025-10-11
//

import SwiftUI

/// App header with icon, title, and tagline
struct AppHeader: View {
    var body: some View {
        VStack(spacing: 12) {
            // Tomato icon - using SF Symbol as placeholder
            // In production, replace with custom tomato icon from Assets
            Image(systemName: "circle.fill")
                .font(.system(size: 48))
                .foregroundColor(Color("PrimaryRed"))
                .shadow(color: Color("PrimaryRed").opacity(0.2), radius: 4, x: 0, y: 2)

            // Title
            Text("Pomodoro Timer")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color("TextDark"))

            // Tagline
            Text("Stay focused, get things done")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color("SecondaryGray"))
        }
    }
}

// MARK: - Preview

#Preview {
    AppHeader()
        .padding()
}
