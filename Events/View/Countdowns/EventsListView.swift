import Foundation
import SwiftUI
import Observation
import PhotosUI
import SwiftData

struct EventsListView: View {
    @Environment(EventViewModel.self) private var viewModel
    @Query(sort: \Event.daysLeft) private var events: [Event]
    @Namespace private var eventsNamespace
    @State private var showPastEvents: Bool = true
    
    @State private var isShowingAddSheet = false
    @State private var gridState: GridState = UserDefaults.standard.savedGridState
    
    @State private var isConfirmingDelete = false
    
    private var columns: [GridItem] {
        gridState == .grid ? Array(repeating: GridItem(.flexible()), count: 2) : [GridItem(.flexible())]
    }
        
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    if events.isEmpty {
                        contentUnavailableView()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 32) {
                                
                                // MARK: Today's Events
                                if !todaysEvents.isEmpty {
                                    VStack(alignment: .leading) {
                                        Text(Strings.EventListViewStrings.todaysEvents)
                                            .font(.headline)

                                        LazyVGrid(columns: columns, spacing: 16) {
                                            ForEach(todaysEvents) { event in
                                                NavigationLink {
                                                    EventDetailView(event: event)
                                                        .navigationTransition(.zoom(sourceID: event.id, in: eventsNamespace))
                                                } label: {
                                                    EventPreview(event: event, gridState: gridState)
                                                        .matchedTransitionSource(id: event.id, in: eventsNamespace)
                                                        .animation(nil, value: event.photoData)
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                // MARK: Upcoming
                                if !upcomingEvents.isEmpty {
                                    VStack(alignment: .leading) {
                                        Text(Strings.EventListViewStrings.upcomingEvents)
                                            .font(.headline)

                                        LazyVGrid(columns: columns, spacing: 16) {
                                            ForEach(upcomingEvents) { event in
                                                NavigationLink {
                                                    EventDetailView(event: event)
                                                        .navigationTransition(.zoom(sourceID: event.id, in: eventsNamespace))
                                                } label: {
                                                    EventPreview(event: event, gridState: gridState)
                                                        .matchedTransitionSource(id: event.id, in: eventsNamespace)
                                                        .animation(nil, value: event.photoData)
                                                }
                                            }
                                        }
                                    }
                                }

                                // MARK: Past
                                if hasPastEvents && showPastEvents {
                                    VStack(alignment: .leading) {
                                        Text(Strings.EventListViewStrings.pastEvents)
                                            .font(.headline)

                                        LazyVGrid(columns: columns, spacing: 16) {
                                            ForEach(pastCountdowns) { event in
                                                NavigationLink {
                                                    EventDetailView(event: event)
                                                        .navigationTransition(.zoom(sourceID: event.id, in: eventsNamespace))
                                                } label: {
                                                    EventPreview(event: event, gridState: gridState)
                                                        .matchedTransitionSource(id: event.id, in: eventsNamespace)
                                                        .animation(nil, value: event.photoData)
                                                }
                                            }
                                        }
                                    }
                                }

                            }
                            .padding()
                        }
                        .animation(.spring(response: 0.4,
                                           dampingFraction: 0.75,
                                           blendDuration: 0.2),
                                   value: gridState)
                        .confirmationDialog(Strings.EventListViewStrings.deletePastEventsConfirmationTitle,
                                            isPresented: $isConfirmingDelete,
                                            titleVisibility: .visible) {
                            Button(Strings.EventListViewStrings.deleteAllPastEventsButton, role: .destructive) {
                                withAnimation {
                                    viewModel.deleteAllPastCountdowns()
                                }
                            }
                            Button(Strings.GeneralStrings.cancel, role: .cancel) {}
                        }
                    }
                }
                .navigationTitle(Strings.GeneralStrings.events)
                .toolbar {
                    if hasPastEvents {
                        ToolbarItem(placement: .navigationBarLeading) {
                            toolbarMenu()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            gridButton()
                            addNewButton()
                        }
                    }
                }
                .fullScreenCover(isPresented: $isShowingAddSheet) {
                    EventFormSheetView()
                }
            }
            .accentColor(.primary)
        }
    }
}

extension EventsListView {
    //Filtering options specific to the View
    
    var upcomingEvents: [Event] {
        events.filter { $0.isUpcoming  }
    }

    var pastCountdowns: [Event] {
        events.filter { $0.isPast  }
    }
    
    var todaysEvents: [Event] {
        events.filter { $0.isToday }
    }
    
    var hasPastEvents: Bool {
        !pastCountdowns.isEmpty
    }

}

private extension EventsListView {
    
    @ViewBuilder
    func gridButton() -> some View {
        Button(action: {
            gridState = gridState == .grid ? .rows : .grid
            UserDefaults.standard.savedGridState = gridState
        }) {
            Image(systemName: gridState == .grid ? "list.bullet" : "square.grid.2x2")
                .contentTransition(.symbolEffect(.automatic))
                .foregroundColor(.accentColor)
        }
        .disabled(events.isEmpty)
        .opacity(events.isEmpty ? 0.6 : 1)
    }
    
    @ViewBuilder
    func initialAddEventButton() -> some View {
        Button(action: {
            isShowingAddSheet = true
        }) {
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .foregroundColor(.accentColor)
                Text(Strings.EventListViewStrings.addNewEvent)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
        }
        .buttonStyle(.bordered)
    }
    
    @ViewBuilder
    func addNewButton() -> some View {
        Button(action: {
            isShowingAddSheet = true
        }) {
            Image(systemName: "calendar.badge.plus")
                .foregroundColor(.accentColor)
        }
    }
    
    @ViewBuilder
    func contentUnavailableView() -> some View {
        ContentUnavailableView(
            label: {
                Label(Strings.EventListViewStrings.noEvents, systemImage: "calendar.badge.exclamationmark")
            },
            description: {
                Text(Strings.EventListViewStrings.emptyListHint)
            },
            actions: {
                initialAddEventButton()
            }
        )
    }
    
    @ViewBuilder
    func toolbarMenu() -> some View {
        Menu {
            if hasPastEvents {
                togglePastEventsButton()
                deletePastEventsButton()
            }
        } label: {
            Label(Strings.GeneralStrings.options, systemImage: "ellipsis.circle")
                .labelStyle(.iconOnly)
        }
    }
    
    @ViewBuilder
    func menuButton(label: String,
                    icon: String? = nil,
                    action: @escaping () -> Void) -> some View {
        Button(action: action) {
            if let icon = icon {
                Label(label, systemImage: icon)
            } else {
                Text(label)
            }
        }
    }
    
    //MARK: Menu buttons
    
    @ViewBuilder
    func togglePastEventsButton() -> some View {
        menuButton(label: showPastEvents ? Strings.EventListViewStrings.hidePastEvents : Strings.EventListViewStrings.showPastEvents,
                   icon: showPastEvents ? "eye.slash" : "eye",
                   action: { showPastEvents.toggle() })

    }
    
    @ViewBuilder
    func deletePastEventsButton() -> some View {
        menuButton(label: Strings.EventListViewStrings.deleteAllPastEventsButton,
                   icon: "trash",
                   action: { isConfirmingDelete = true })
        .foregroundStyle(.red)

    }
}
