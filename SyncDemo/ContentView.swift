//
//  ContentView.swift
//  SyncDemo
//

import SwiftUI

struct ContentView: View {
    let valuesManager: ValuesManager

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Text("Current value")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(valuesManager.currentValue)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
            }

            Spacer()

            Button("Shuffle") {
                withAnimation { valuesManager.shuffle() }
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding()
    }
}

#Preview {
    ContentView(valuesManager: ValuesManager())
}
