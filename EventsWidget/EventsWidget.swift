//
//  EventsWidget.swift
//  EventsWidget
//
//  Created by Luka Lešić on 02.05.25.
//

import WidgetKit
import SwiftUI
import SwiftData

//widgetcenter.shared.reloadtimeline()

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
        return Timeline(entries: [entry], policy: .never) //TODO change never to time
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let event: Event
}

struct EventsWidgetEntryView: View {
    
//    @Query(sort: \Event.daysLeft, animation: .bouncy) private var events: [Event]
    
    var entry: Provider.Entry
    var event: Event { entry.event }

    var body: some View {
        ZStack {
            ContainerRelativeShape().fill(event.color.gradient)
//            
//            ForEach(events) { event in
//                Text(event.name)
//            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(event.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(event.color).brightness(0.7)
                    .shadow(color: .black.opacity(0.5), radius: 4)

                Spacer()
                
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(event.emoji)
                            .font(.title2)
                            .shadow(color: .black.opacity(0.5), radius: 4)
                        
                        Text(event.date, style: .date)
                            .font(.caption)
                            .foregroundColor(event.color).brightness(0.7)
                            .shadow(color: .black.opacity(0.5), radius: 4)

                    }
                    
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
                .modelContainer(for: Event.self)
        }
        .configurationDisplayName("Test")
        .description("Test description")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

extension Event {
    static let sample = Event(id: UUID(), color: .green, daysLeft: 35, name: "Test", descriptionText: "", emoji: "😀", priority: .medium, date: .now, includesTime: true, isAddedToCalendar: false, photo: nil, repeatFrequency: .none)
}
