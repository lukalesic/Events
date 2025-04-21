//
//  CountdownVM.swift
//  Events
//
//  Created by Luka Lešić on 20.04.25.
//

//import Foundation
//import SwiftUICore
//import UIKit
//
//@Observable
//class CountdownVM: Identifiable {
//    
//    private var countdown: Countdown
//    
//    init(countdown: Countdown) {
//        self.countdown = countdown
//    }
//    
//    // MARK: - Computed Properties with Getters & Setters
//    
//    var id: UUID {
//        countdown.id
//    }
//    
//    var color: Color {
//        get { countdown.color }
//        set { countdown.color = newValue }
//    }
//    
//    var daysLeft: Int {
//        get { countdown.daysLeft }
//        set { countdown.daysLeft = newValue }
//    }
//
//    var name: String {
//        get { countdown.name }
//        set { countdown.name = newValue }
//    }
//    
//    var description: String {
//        get { countdown.descriptionText }
//        set { countdown.descriptionText = newValue }
//    }
//    
//    var emoji: String {
//        get { countdown.emoji }
//        set { countdown.emoji = newValue }
//    }
//    
//    var priority: EventPriority {
//        get { countdown.priority }
//        set { countdown.priority = newValue }
//    }
//    
//    var date: Date {
//        get { countdown.date }
//        set { countdown.date = newValue }
//    }
//    
//    var photo: UIImage? {
//        get { countdown.photo }
//        set { countdown.photo = newValue }
//    }
//    
//    var repeatFrequency: RepeatFrequency {
//        get { countdown.repeatFrequency }
//        set { countdown.repeatFrequency = newValue }
//    }
//    
//    // MARK: - Read-only Derived Properties
//    
//    var nextDate: Date {
//        countdown.nextDate
//    }
//    
//    var daysLeftUntilNextDate: Int {
//        countdown.daysLeftUntilNextDate
//    }
//}
