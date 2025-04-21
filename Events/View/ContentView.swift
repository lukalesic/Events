//
//  ContentView.swift
//  Events
//
//  Created by Luka Lešić on 23.03.25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var countdownViewModel: CountdownViewModel?
    
    var body: some View {
        TabView {
            if let viewModel = countdownViewModel {
                CountdownView()
                    .environment(viewModel)
                    .tabItem {
                        Label(Strings.tabBarCountdown, systemImage: "calendar.badge.clock")
                    }
                
                DaysSinceView()
                    .tabItem {
                        Label(Strings.tabBarDaysSince, systemImage: "calendar.badge.checkmark")
                    }
                
                BirthdaysView()
                    .tabItem {
                        Label(Strings.tabBarBirthdays, systemImage: "calendar.and.person")
                    }
            } else {
                ProgressView("Loading...")
            }
        }
        .accentColor(.primary)
        .onAppear {
            countdownViewModel = CountdownViewModel(modelContext: modelContext)
        }
    }
}

