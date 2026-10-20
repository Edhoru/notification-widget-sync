//
//  SyncDemoApp.swift
//  SyncDemo
//

import SwiftUI

@main
struct SyncDemoApp: App {
    @State private var valuesManager = ValuesManager()

    var body: some Scene {
        WindowGroup {
            ContentView(valuesManager: valuesManager)
        }
    }
}
