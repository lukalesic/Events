//
//  UserDefaults+Extension.swift
//  Events
//
//  Created by Luka Lešić on 20.04.25.
//

import Foundation

extension UserDefaults {
    private enum Keys {
        static let selectedDisplayMode = "selectedDisplayMode"
        static let gridState = "gridState"
        static let showEventPreviewBackground = "showEventPreviewBackground"
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
    
    var savedGridState: GridState {
        get {
            guard let raw = string(forKey: Keys.gridState),
                  let state = GridState(rawValue: raw) else {
                return .rows
            }
            return state
        }
        set {
            set(newValue.rawValue, forKey: Keys.gridState)
        }
    }
    
    var savedShowEventPreviewBackground: Bool {
        get {
            object(forKey: Keys.showEventPreviewBackground) as? Bool ?? false
        }
        set {
            set(newValue, forKey: Keys.showEventPreviewBackground)
        }
    }
}
