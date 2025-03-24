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
        let testCountdown = Countdown(daysLeft: 33, name: "name", description: "desc", emoji: "", priority: .small)
        
        let testCountdown2 = Countdown(daysLeft: 33, name: "name", description: "desc", emoji: "", priority: .small)
        
        let testCountdown3 = Countdown(daysLeft: 33, name: "name", description: "desc", emoji: "", priority: .small)

        self.countdowns.append(testCountdown)
        self.countdowns.append(testCountdown2)
        self.countdowns.append(testCountdown3)
    }
}

struct Countdown: Identifiable {
    var id = UUID()
    var color: Color = Countdown.randomColor() // Directly store a Color
    var daysLeft: Int
    var name: String
    var description: String
    var emoji: String
    var priority: Priority
    
    // Function to return a random SwiftUI Color
    static func randomColor() -> Color {
        let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink]
        return colors.randomElement() ?? .gray // Default to gray if no color is found
    }
}

enum Priority {
    case small
    case medium
    case large
}
