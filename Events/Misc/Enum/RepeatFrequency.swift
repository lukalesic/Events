//
//  RepeatFrequency.swift
//  Events
//
//  Created by Luka Lešić on 20.04.25.
//

import Foundation

enum RepeatFrequency: String, CaseIterable, Identifiable {
    case none = "None"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"

    var id: String { self.rawValue }
}
