 //
//  EventsApp.swift
//  Events
//
//  Created by Luka Lešić on 23.03.25.
//

import SwiftUI
import SwiftData

@main
struct EventsApp: App {
    init() {
        _ = NotificationManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Event.self)
    }
}

