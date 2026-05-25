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
        static let showPastEvents = "showPastEvents"
        static let remind1DayBefore = "remind1DayBefore"
        static let remind3DaysBefore = "remind3DaysBefore"
        static let defaultNotificationHour = "defaultNotificationHour"
        static let defaultNotificationMinute = "defaultNotificationMinute"
    }

    var savedDisplayMode: TimeDisplayMode {
        get {
            guard let raw = string(forKey: Keys.selectedDisplayMode),
                  let mode = TimeDisplayMode(rawValue: raw) else {
                return .automatic // fallback
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
    
    var savedShowPastEvents: Bool {
        get {
            object(forKey: Keys.showPastEvents) as? Bool ?? true
        }
        set {
            set(newValue, forKey: Keys.showPastEvents)
        }
    }
    
    var remind1DayBefore: Bool {
        get {
            object(forKey: Keys.remind1DayBefore) as? Bool ?? true
        }
        set {
            set(newValue, forKey: Keys.remind1DayBefore)
        }
    }
    
    var remind3DaysBefore: Bool {
        get {
            object(forKey: Keys.remind3DaysBefore) as? Bool ?? false
        }
        set {
            set(newValue, forKey: Keys.remind3DaysBefore)
        }
    }
    
    var defaultNotificationHour: Int {
        get {
            object(forKey: Keys.defaultNotificationHour) as? Int ?? 10
        }
        set {
            set(newValue, forKey: Keys.defaultNotificationHour)
        }
    }
    
    var defaultNotificationMinute: Int {
        get {
            object(forKey: Keys.defaultNotificationMinute) as? Int ?? 0
        }
        set {
            set(newValue, forKey: Keys.defaultNotificationMinute)
        }
    }
}
