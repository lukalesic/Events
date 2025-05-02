//
//  EventsWidgetBundle.swift
//  EventsWidget
//
//  Created by Luka Lešić on 02.05.25.
//

import WidgetKit
import SwiftUI

@main
struct EventsWidgetBundle: WidgetBundle {
    var body: some Widget {
        EventsWidget()
        EventsWidgetControl()
    }
}
