//
//  CountdownViewModel.swift
//  Events
//
//  Created by Luka Lešić on 23.03.25.
//

import Foundation
import SwiftUI
import Observation

@Observable
class CountdownViewModel {
    
    var countdowns: [Countdown] = []
    
    init() {
        let testCountdown = Countdown(daysLeft: 33, name: "namenamenamenamenam namee even longer name 2 rows and even three rows, perhaps", description: "desc", emoji: "🔥", priority: .small, date: .now)
        
        let testCountdown2 = Countdown(daysLeft: 33, name: "name", description: "desc", emoji: "🔥", priority: .small, date: .now)
        
        let testCountdown3 = Countdown(daysLeft: 33, name: "name", description: "desc", emoji: "🔥", priority: .small, date: .now)
        
        let testCountdown4 = Countdown(daysLeft: 33, name: "name", description: "desc", emoji: "🔥", priority: .small, date: .now)
        
        let testCountdown5 = Countdown(daysLeft: 33, name: "name", description: "desc", emoji: "🔥", priority: .small, date: .now)



        self.countdowns.append(testCountdown)
        self.countdowns.append(testCountdown2)
        self.countdowns.append(testCountdown3)
        self.countdowns.append(testCountdown4)
        self.countdowns.append(testCountdown5)
    }
}

struct Countdown: Identifiable {
    var id = UUID()
    var color: Color = Countdown.randomColor()
    var daysLeft: Int
    var name: String
    var description: String
    var emoji: String
    var priority: Priority
    var date: Date

    // Function to return a random SwiftUI Color
    static func randomColor() -> Color {
        let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink]
        return colors.randomElement() ?? .gray
    }
}

enum Priority {
    case small
    case medium
    case large
}
