import Foundation
import SwiftUI
import Observation
import PhotosUI
import SwiftData

struct CountdownView: View {
    @Environment(CountdownViewModel.self) private var viewModel
    @Query private var countdowns: [Countdown]
    @Namespace private var countdownsNamespace
    
    @State private var isShowingAddSheet = false
    @State private var gridState: GridState = UserDefaults.standard.savedGridState
    
    private var columns: [GridItem] {
        gridState == .grid ? Array(repeating: GridItem(.flexible()), count: 2) : [GridItem(.flexible())]
    }
    
    var upcomingCountdowns: [Countdown] {
        countdowns.filter { !$0.isPast  }
    }

    var pastCountdowns: [Countdown] {
        countdowns.filter { $0.isPast  }
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
                                if !pastCountdowns.isEmpty {
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
                        }
                        .padding()
                        .animation(.spring(response: 0.4,
                                           dampingFraction: 0.75,
                                           blendDuration: 0.2),
                                   value: gridState)
                    }
                }
                .navigationTitle("Countdowns")
                .toolbar {
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
    
}
