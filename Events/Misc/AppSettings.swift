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
    
    var showEventPreviewBackground: Bool = true
    
    private init() {}
}
