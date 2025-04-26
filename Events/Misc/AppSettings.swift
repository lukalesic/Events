//
//  AppSettings.swift
//  Events
//
//  Created by Luka Lešić on 26.04.25.
//

import Foundation

@Observable
class AppSettings {
    static let shared = AppSettings()
    
    var showEventPreviewBackground: Bool {
        didSet {
            UserDefaults.standard.savedShowEventPreviewBackground = showEventPreviewBackground
        }
    }
    
    private init() {
        self.showEventPreviewBackground = UserDefaults.standard.savedShowEventPreviewBackground
    }
}
