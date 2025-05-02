//
//  EventsWidget.swift
//  EventsWidget
//
//  Created by Luka Lešić on 02.05.25.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), event: .sample)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration, event: .sample)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let currentDate = Date()
        let entry = SimpleEntry(date: currentDate, configuration: configuration, event: .sample)
        return Timeline(entries: [entry], policy: .never)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let event: WidgetEvent
}

struct EventsWidgetEntryView: View {
    var entry: Provider.Entry
    var event: WidgetEvent { entry.event }

    var body: some View {
        ZStack {
            ContainerRelativeShape().fill(event.color.gradient)
            VStack(alignment: .leading, spacing: 6) {
                Text(event.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(event.color).brightness(0.7)
                    .shadow(color: .black.opacity(0.5), radius: 4)

                Spacer()
                
                HStack {
                    Text(event.emoji)
                        .font(.title2)
                        .shadow(color: .black.opacity(0.5), radius: 4)

                    Spacer()

                    VStack {
                        Text("\(event.daysLeftUntilNextDate)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(event.color).brightness(0.7)
                            .shadow(color: .black.opacity(0.5), radius: 4)

                        Text(event.daysLeftUntilNextDate == 1 ? "Day" : "Days")
                            .font(.caption)
                            .foregroundColor(event.color).brightness(0.7)
                            .shadow(color: .black.opacity(0.5), radius: 4)

                    }
                }
            }
            .padding()
        }
    }
}

struct EventsWidget: Widget {
    let kind: String = "EventsWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            EventsWidgetEntryView(entry: entry)
        }
        .contentMarginsDisabled()
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}
