//
//  AppIntent.swift
//  EventsWidget
//
//  Created by Luka Lešić on 02.05.25.
//

import WidgetKit
import AppIntents
import SwiftData

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    
    
    static var title: LocalizedStringResource { "Choose an event" }
    static var description: IntentDescription { "Choose your favorite event." }
    
    @Parameter(title: "Event", default: nil)
    var event: EventEntity?
}

struct EventEntity: AppEntity {
    var id: UUID
    var name: String
    
    static var defaultQuery = EventQuery()
        
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Event"
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
    
}

struct EventQuery: EntityQuery {
    
    func entities(for identifiers: [Entity.ID]) async throws -> [EventEntity] {
        try await suggestedEntities().filter({identifiers.contains($0.id)})
    }
    
    @MainActor
    func suggestedEntities() async throws -> [EventEntity] {
        let container = try? ModelContainer(for: Event.self)
        let sort = [SortDescriptor(\Event.name)]
        let descriptor = FetchDescriptor<Event>(sortBy: sort)
        let allEvents = try? container?.mainContext.fetch(descriptor)

        let allEntities = allEvents?.map({ event in
            EventEntity(id: event.id, name: event.name)
        })
        return allEntities ?? []
    }
    
    func defaultResult() async -> EventEntity? {
        try? await suggestedEntities().first
    }
}
