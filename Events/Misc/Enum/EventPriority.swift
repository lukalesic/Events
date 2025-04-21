//
//  Priority.swift
//  Events
//
//  Created by Luka Lešić on 20.04.25.
//

import Foundation

enum EventPriority: String, CaseIterable, Codable {
    case small
    case medium
    case large

    var displayName: String {
        switch self {
        case .small: return "Low"
        case .medium: return "Medium"
        case .large: return "High"
        }
    }
}
