//
//  UserDefaults+Extension.swift
//  Events
//
//  Created by Luka Lešić on 20.04.25.
//

import Foundation

//TODO MERGE

extension UserDefaults {
    private enum Keys {
        static let selectedDisplayMode = "selectedDisplayMode"
    }

    var savedDisplayMode: TimeDisplayMode {
        get {
            guard let raw = string(forKey: Keys.selectedDisplayMode),
                  let mode = TimeDisplayMode(rawValue: raw) else {
                return .days // fallback
            }
            return mode
        }
        set {
            set(newValue.rawValue, forKey: Keys.selectedDisplayMode)
        }
    }
}
