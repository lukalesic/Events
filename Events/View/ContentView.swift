//
//  ContentView.swift
//  Events
//
//  Created by Luka Lešić on 23.03.25.
//

import SwiftUI

struct ContentView: View {
    
    @State private var countdownViewModel = CountdownViewModel()

    var body: some View {
        TabView {
            CountdownView()
                .environment(countdownViewModel)
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

        }

    }
}
