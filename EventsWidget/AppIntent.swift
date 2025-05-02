//
//  AppIntent.swift
//  EventsWidget
//
//  Created by Luka Lešić on 02.05.25.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Luka" }
    static var description: IntentDescription { "This is a widget." }

    // An example configurable parameter.
    @Parameter(title: "Favorite Luka", default: "😃")
    var favoriteEmoji: String
}
