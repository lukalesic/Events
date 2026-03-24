import Foundation
import SwiftUI
import Observation
import PhotosUI
import SwiftData

struct EventsListView: View {
    @State private var refreshOnAppResume = false
    @State private var animateBlocks = false
    @Environment(EventViewModel.self) private var viewModel
    @Query(sort: \Event.daysLeft, animation: .bouncy) private var events: [Event]
    @Namespace private var eventsNamespace
    @State private var showPastEvents: Bool = UserDefaults.standard.savedShowPastEvents
    @State private var isGridButtonDisabled = false
    @State private var isShowingAddSheet = false
    @State private var gridState: GridState = UserDefaults.standard.savedGridState
    
    @State private var isConfirmingDelete = false
    
    private var columns: [GridItem] {
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad

        return gridState == .grid ? Array(repeating: GridItem(.flexible()), count: isIpad ? 3 : 2) : [GridItem(.flexible())]
    }
    
    private var blockSpacing: CGFloat {
        gridState == .grid ? 10 : 16
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
                                            
                                            LazyVGrid(columns: columns, spacing: blockSpacing) {
                                                ForEach(Array(todaysEvents.enumerated()), id: \.element.id) { index, event in
                                                    eventPreviewLink(for: event, index: index)
                                                }
                                            }
                                        }
                                    }
                                    
                                    // MARK: Upcoming
                                    if !upcomingEvents.isEmpty {
                                        VStack(alignment: .leading) {
                                            Text(Strings.EventListViewStrings.upcomingEvents)
                                                .font(.headline)
                                            
                                            LazyVGrid(columns: columns, spacing: blockSpacing) {
                                                ForEach(Array(upcomingEvents.enumerated()), id: \.element.id) { index, event in
                                                    eventPreviewLink(for: event, index: index)
                                                }
                                            }
                                        }
                                    }
                                    
                                    // MARK: Past
                                    if hasPastEvents {
                                        VStack(alignment: .leading) {
                                            Button {
                                                withAnimation(.easeInOut(duration: 0.45)) {
                                                    showPastEvents.toggle()
                                                    UserDefaults.standard.savedShowPastEvents = showPastEvents
                                                }
                                            } label: {
                                                HStack(spacing: 12) {
                                                    Text(Strings.EventListViewStrings.pastEvents)
                                                        .font(.headline)
                                                    Image(systemName: "chevron.right")
                                                        .font(.system(size: 14, weight: .semibold))
                                                        .rotationEffect(.degrees(showPastEvents ? 90 : 0))
                                                        .background(Color.gray.opacity(0.2).clipShape(Circle()).scaleEffect(2.12))
                                                }
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .foregroundStyle(.primary)
                                            }
                                            .buttonStyle(.plain)
                                            
                                            if showPastEvents {
                                                LazyVGrid(columns: columns, spacing: blockSpacing) {
                                                    ForEach(Array(pastCountdowns.enumerated()), id: \.element.id) { index, event in
                                                        eventPreviewLink(for: event, index: index)
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
                        ToolbarItem(placement: .navigationBarLeading) {
                            toolbarMenu()
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            HStack(spacing: 5) {
                                gridButton()
                            }
                            .padding(.horizontal, 4)
                        }
                        
                    }
                    .sheet(isPresented: $isShowingAddSheet) {
                        EventFormSheetView()
                            .navigationTransition(.zoom(sourceID: "addEventButton", in: eventsNamespace))
                    }
                    
                    .overlay(
                        floatingAddEventButton()
                            .padding([.trailing])
                            .offset(y: 10),
                        alignment: .bottomTrailing
                    )
                    
                }
            .task {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.3)) {
                    animateBlocks = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                refreshOnAppResume.toggle()
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
    func eventPreviewLink(for event: Event, index: Int) -> some View {
        NavigationLink {
            EventDetailView(event: event)
                .navigationTransition(.automatic)
        } label: {
            EventPreview(event: event, gridState: gridState)
                .animation(nil, value: event.photoData)
                .shadow(color: Color.black.opacity(0.22), radius: 5, x: 0, y: 0)
                .scaleEffect(animateBlocks ? 1 : 0.8)
                .opacity(animateBlocks ? 1 : 0)
                .blur(radius: animateBlocks ? 0 : 4)
                .animation(.spring(response: 0.5, dampingFraction: 0.8)
                            .delay(Double(index) * 0.05),
                           value: animateBlocks)
        }
        .contextMenu {
            Button(role: .destructive) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation {
                        viewModel.delete(event)
                    }
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    @ViewBuilder
    func gridButton() -> some View {
        Button(action: {
            gridState = gridState == .grid ? .rows : .grid
            UserDefaults.standard.savedGridState = gridState
            
            if AppSettings.shared.showEventPreviewBackground {
                isGridButtonDisabled = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    isGridButtonDisabled = false
                }
            }
        }) {
            Image(systemName: gridState == .grid ? "list.bullet" : "square.grid.2x2")
                .contentTransition(.symbolEffect(.automatic))
                .foregroundColor(.accentColor)
        }
        .disabled(events.isEmpty || isGridButtonDisabled)
        .opacity((events.isEmpty || isGridButtonDisabled) ? 0.6 : 1)
        .animation(.easeInOut(duration: 0.3), value: isGridButtonDisabled)
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
                deletePastEventsButton()
            }
//            showPreviewImagesButton()
            
        } label: {
            Label(Strings.GeneralStrings.options, systemImage: "gear")
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
    func deletePastEventsButton() -> some View {
        menuButton(label: Strings.EventListViewStrings.deleteAllPastEventsButton,
                   icon: "trash",
                   action: { isConfirmingDelete = true })
        .foregroundStyle(.red)
        
    }
    
    @ViewBuilder
    func showPreviewImagesButton() -> some View {
        menuButton(
            label: AppSettings.shared.showEventPreviewBackground ? "Hide Event Previews" : "Show Event Previews",
            icon: AppSettings.shared.showEventPreviewBackground ? "eye.slash" : "eye",
            action: {
                withAnimation {
                    AppSettings.shared.showEventPreviewBackground.toggle()
                }
            }
        )
    }
    
    @ViewBuilder
    func floatingAddEventButton() -> some View {
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad
        Button(action: {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isShowingAddSheet = true
            }
        }) {
            if #available(iOS 26.0, *) {
                ZStack {
                    HStack(spacing: isIpad ? 12 : 0) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 25, weight: .semibold))
                        if isIpad {
                            Text("Add new event")
                                .font(.system(size: 20, weight: .semibold))
                        }
                    }
                }
                .frame(width: isIpad ? 220 : 64, height: isIpad ? 80 : 64)
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
                .glassEffect(.regular.interactive())
                .matchedTransitionSource(id: "addEventButton", in: eventsNamespace)
                .offset(x: isIpad ? 0 : 13, y: isIpad ? 0 : 15)
            } else {
                ZStack {
                    Capsule()
                        .fill(Color.blue.opacity(0.2))
                    HStack(spacing: isIpad ? 12 : 0) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 28, weight: .light))
                            .foregroundColor(.accentColor)
                        if isIpad {
                            Text("Add new event")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .frame(width: isIpad ? 220 : 64, height: 64)
                .buttonBorderShape(.capsule)
                .matchedTransitionSource(id: "addEventButton", in: eventsNamespace)
                .accessibilityLabel("Add New Event")
                .offset(x: isIpad ? 0 : 13, y: isIpad ? 0 : 15)
            }
        }
        .allowsHitTesting(!isShowingAddSheet)
        .padding(.bottom, 18)
        .padding(.horizontal, isIpad ? 0 : 18)
        .frame(maxWidth: .infinity, alignment: isIpad ? .center : .trailing)
    }
}
