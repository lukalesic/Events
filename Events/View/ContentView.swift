//
//  ContentView.swift
//  Events
//
//  Created by Luka Lešić on 23.03.25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var countdownViewModel: EventViewModel?
    
    var body: some View {
        TabView {
            if let viewModel = countdownViewModel {
                EventsListView()
                    .environment(viewModel)
                    .tabItem {
                        Label(Strings.TabBarStrings.tabBarEvents, systemImage: "calendar.badge.clock")
                    }
                
                DaysSinceView()
                    .tabItem {
                        Label(Strings.TabBarStrings.tabBarDaysSince, systemImage: "calendar.badge.checkmark")
                    }
                
                BirthdaysView()
                    .tabItem {
                        Label(Strings.TabBarStrings.tabBarBirthdays, systemImage: "calendar.and.person")
                    }
            } else {
                ProgressView("Loading...")
            }
        }
        .accentColor(.primary)
        .onAppear {
            countdownViewModel = EventViewModel(modelContext: modelContext)
        }
    }
}

