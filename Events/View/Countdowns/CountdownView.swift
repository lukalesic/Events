import Foundation
import SwiftUI
import Observation
import PhotosUI
import SwiftData

struct CountdownView: View {
    @Environment(CountdownViewModel.self) private var viewModel
    @Query(sort: \Countdown.daysLeft) private var countdowns: [Countdown]
    @Namespace private var countdownsNamespace
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
                    if countdowns.isEmpty {
                        contentUnavailableView()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 32) {
                                
                                // MARK: Today's Events
                                if !todaysCountdowns.isEmpty {
                                    VStack(alignment: .leading) {
                                        Text("Today's Events")
                                            .font(.headline)

                                        LazyVGrid(columns: columns, spacing: 16) {
                                            ForEach(todaysCountdowns) { countdown in
                                                NavigationLink {
                                                    CounterDetailView(countdown: countdown)
                                                        .navigationTransition(.zoom(sourceID: countdown.id, in: countdownsNamespace))
                                                } label: {
                                                    CounterBlockView(countdown: countdown, gridState: gridState)
                                                        .matchedTransitionSource(id: countdown.id, in: countdownsNamespace)
                                                        .animation(nil, value: countdown.photoData)
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                // MARK: Upcoming
                                if !upcomingCountdowns.isEmpty {
                                    VStack(alignment: .leading) {
                                        Text("Upcoming Events")
                                            .font(.headline)

                                        LazyVGrid(columns: columns, spacing: 16) {
                                            ForEach(upcomingCountdowns) { countdown in
                                                NavigationLink {
                                                    CounterDetailView(countdown: countdown)
                                                        .navigationTransition(.zoom(sourceID: countdown.id, in: countdownsNamespace))
                                                } label: {
                                                    CounterBlockView(countdown: countdown, gridState: gridState)
                                                        .matchedTransitionSource(id: countdown.id, in: countdownsNamespace)
                                                        .animation(nil, value: countdown.photoData)
                                                }
                                            }
                                        }
                                    }
                                }

                                // MARK: Past
                                if hasPastEvents && showPastEvents {
                                    VStack(alignment: .leading) {
                                        Text("Past Events")
                                            .font(.headline)

                                        LazyVGrid(columns: columns, spacing: 16) {
                                            ForEach(pastCountdowns) { countdown in
                                                NavigationLink {
                                                    CounterDetailView(countdown: countdown)
                                                        .navigationTransition(.zoom(sourceID: countdown.id, in: countdownsNamespace))
                                                } label: {
                                                    CounterBlockView(countdown: countdown, gridState: gridState)
                                                        .matchedTransitionSource(id: countdown.id, in: countdownsNamespace)
                                                        .animation(nil, value: countdown.photoData)
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
                        .confirmationDialog("Are you sure you want to delete all past events?",
                                            isPresented: $isConfirmingDelete,
                                            titleVisibility: .visible) {
                            Button("Delete All Past Events", role: .destructive) {
                                withAnimation {
                                    viewModel.deleteAllPastCountdowns()
                                }
                            }
                            Button("Cancel", role: .cancel) {}
                        }
                    }
                }
                .navigationTitle("Events")
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
                    CountdownFormSheetView()
                }
            }
            .accentColor(.primary)
        }
    }
}

extension CountdownView {
    //Filtering options specific to the View
    
    var upcomingCountdowns: [Countdown] {
        countdowns.filter { $0.isUpcoming  }
    }

    var pastCountdowns: [Countdown] {
        countdowns.filter { $0.isPast  }
    }
    
    var todaysCountdowns: [Countdown] {
        countdowns.filter { $0.isToday }
    }
    
    var hasPastEvents: Bool {
        !pastCountdowns.isEmpty
    }

}

private extension CountdownView {
    
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
        .disabled(countdowns.isEmpty)
        .opacity(countdowns.isEmpty ? 0.6 : 1)
    }
    
    @ViewBuilder
    func initialAddEventButton() -> some View {
        Button(action: {
            isShowingAddSheet = true
        }) {
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .foregroundColor(.accentColor)
                Text("Add new countdown")
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
                Label("No Countdowns", systemImage: "calendar.badge.exclamationmark")
            },
            description: {
                Text("When you add a new countdown, it will appear here.")
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
            Label("Options", systemImage: "ellipsis.circle")
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
        menuButton(label: showPastEvents ? "Hide Past Events" : "Show Past Events",
                   icon: showPastEvents ? "eye.slash" : "eye",
                   action: { showPastEvents.toggle() })

    }
    
    @ViewBuilder
    func deletePastEventsButton() -> some View {
        menuButton(label: "Delete All Past Events",
                   icon: "trash",
                   action: { isConfirmingDelete = true })
        .foregroundStyle(.red)

    }
}
