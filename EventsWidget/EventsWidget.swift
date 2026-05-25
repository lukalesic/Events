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
    
    var container: ModelContainer = {
        try! ModelContainer(for: Event.self)
    }()
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), event: .sample)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let selectedEvent: Event?
        if configuration.showNextUpcoming {
            selectedEvent = try? await getNextUpcomingEvent()
        } else {
            selectedEvent = try? await getEvent(name: configuration.event?.name)
        }
        
        return SimpleEntry(date: Date(), configuration: configuration, event: selectedEvent)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let currentDate = Date.now

        let selectedEvent: Event?
        if configuration.showNextUpcoming {
            selectedEvent = try? await getNextUpcomingEvent()
        } else {
            selectedEvent = try? await getEvent(name: configuration.event?.name)
        }
        
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: currentDate)
        let nextMidnight = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        
        // For next upcoming mode, also refresh when the event's date passes
        var refreshDate = nextMidnight
        if configuration.showNextUpcoming, let event = selectedEvent {
            if event.date > currentDate && event.date < nextMidnight {
                refreshDate = event.date
            }
        }

        let entry = SimpleEntry(date: currentDate, configuration: configuration, event: selectedEvent)
        return Timeline(entries: [entry], policy: .after(refreshDate))
    }
    
    @MainActor
    func getEvent(name: String?) throws -> Event? {
        guard let name else {
            return nil
        }
        
        let predicate = #Predicate<Event> { $0.name == name }
        let descriptor = FetchDescriptor<Event>(predicate: predicate)
        let foundEvents = try? container.mainContext.fetch(descriptor)
        return foundEvents?.first
    }
    
    @MainActor
    func getNextUpcomingEvent() throws -> Event? {
        let now = Date.now
        let predicate = #Predicate<Event> { $0.date >= now }
        var descriptor = FetchDescriptor<Event>(predicate: predicate, sortBy: [SortDescriptor(\Event.date, order: .forward)])
        descriptor.fetchLimit = 1
        let results = try? container.mainContext.fetch(descriptor)
        return results?.first
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let event: Event?
}

struct EventsWidget: Widget {
    let kind: String = "EventsWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            EventsWidgetEntryView(entry: entry)
                .modelContainer(for: Event.self)
                .containerBackground(.tertiary, for: .widget)
        }
        .configurationDisplayName("Events")
        .description("Test description")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

struct EventsWidgetEntryView: View {
        
    var entry: Provider.Entry

    var body: some View {
        if let event = entry.event {
            ZStack {
                ContainerRelativeShape().fill(event.color.gradient)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(event.displayName)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
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
                            
                            if event.daysLeftUntilNextDate != 0 {
                                Text(event.date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(event.color).brightness(0.7)
                                    .shadow(color: .black.opacity(0.5), radius: 4)
                            }
                        }
                        
                        Spacer()
                        
                        VStack {
                            let daysLeft = event.daysLeftUntilNextDate
                            
                            if daysLeft != 0 {
                                VStack {
                                    Text(abs(daysLeft).formatted()) // Always show positive number
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(event.color).brightness(0.7)
                                        .shadow(color: .black.opacity(0.5), radius: 4)
                                    
                                    Text(
                                        daysLeft == 0
                                        ? "Today"
                                        : daysLeft > 0
                                        ? (daysLeft == 1 ? "Day" : "Days")
                                        : (abs(daysLeft) == 1 ? "Day Ago" : "Days Ago")
                                    )
                                    .font(.caption)
                                    .foregroundColor(event.color).brightness(0.7)
                                    .shadow(color: .black.opacity(0.5), radius: 4)
                                }
                            }
                            else {
                                Text("Today")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(event.color).brightness(0.7)
                                    .shadow(color: .black.opacity(0.5), radius: 4)

                            }
                        }
                    }
                }
                .padding()
            }
            .widgetURL(URL(string: "events://open/\(event.id.uuidString)"))
        }
        else {
            ZStack {
                ContainerRelativeShape().fill(.thinMaterial)

                if entry.configuration.showNextUpcoming {
                    ContentUnavailableView("No Upcoming Events",
                                           systemImage: "calendar",
                                           description: Text("All events have passed"))
                } else {
                    ContentUnavailableView("No Event",
                                           systemImage: "calendar",
                                           description: Text("Edit this widget to select an event"))
                }
            }
        }
    }
}

extension Event {
    static let sample = Event(color: .green, daysLeft: 35, name: "Test", descriptionText: "", emoji: "😀", priority: .medium, date: .now, includesTime: true, isAddedToCalendar: false, photo: nil, repeatFrequency: .none)
}
