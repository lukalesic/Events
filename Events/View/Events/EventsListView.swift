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
    @Namespace private var settingsNamespace
    @State private var showPastEvents: Bool = UserDefaults.standard.savedShowPastEvents
    @State private var isGridButtonDisabled = false
    @State private var isShowingAddSheet = false
    @State private var gridState: GridState = UserDefaults.standard.savedGridState
    
    @State private var isConfirmingDelete = false
    @State private var isShowingSettings = false
    @State private var hasFinishedInitialLoad = false
    @State private var navigateToEvent: Event?
    @State private var filterMode: EventFilterMode = .all
    
    enum EventFilterMode: String, CaseIterable {
        case all = "All"
        case events = "Events"
        case birthdays = "Birthdays"
    }
    
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
                if #available(iOS 26.0, *) {
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
                                            HStack {
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
                                                    .foregroundStyle(.primary)
                                                }
                                                
                                                Spacer()
                                                
                                                if showPastEvents {
                                                    deletePastEventsView()
                                                }
                                            }
                                            
                                            
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
                                .padding(.bottom, 80)
                            }
                            
                            .animation(.spring(response: 0.4,
                                               dampingFraction: 0.75,
                                               blendDuration: 0.2),
                                       value: gridState)
                            
                        }
                    }
                    .navigationTitle(Strings.GeneralStrings.events)
                    .toolbar {
                        if #available(iOS 26.0, *) {
                            ToolbarItem(placement: .navigationBarLeading) {
                                settingsButton()
                            }
                            .matchedTransitionSource(id: "settingsButton", in: settingsNamespace)
                        } else {
                            ToolbarItem(placement: .navigationBarLeading) {
                                settingsButton()
                            }
                        }
                        
                        //                        if #available(iOS 26.0, *) {
                        //                            ToolbarItem(placement: .bottomBar) {
                        ////                                bottomBar()
                        //                                Button("A") {
                        //                                    //
                        //                                }
                        ////                                .buttonStyle(.glassProminent)
                        //                                .glassEffect(.regular)
                        //                            }
                        //                            .sharedBackgroundVisibility(.hidden)
                        //                        }
                    }
                    .sheet(isPresented: $isShowingAddSheet) {
                        EventEditSheet()
                            .navigationTransition(.zoom(sourceID: "addEventButton", in: eventsNamespace))
                    }
                    .sheet(isPresented: $isShowingSettings) {
                        SettingsView()
                            .navigationTransition(.zoom(sourceID: "settingsButton", in: settingsNamespace))
                            .onDisappear {
                                withAnimation {
                                    gridState = UserDefaults.standard.savedGridState
                                }
                            }
                    }
                    .safeAreaBar(edge: .bottom, alignment: .center, content: {
                        bottomBar()
                            .padding(.horizontal)
                            .padding(.top, 30)
                            .padding(.bottom, -20)

                    })
                } else {
                    // Fallback on earlier versions
                }
//                    .overlay(
//                        bottomBar()
//                            .padding(.horizontal)
//                            .padding(.bottom, 8),
//                        alignment: .bottom
//                    )
                    
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
            .navigationDestination(item: $navigateToEvent) { event in
                EventDetailView(event: event)
            }
            .onAppear {
                NotificationManager.shared.onNotificationTapped = { eventID in
                    navigateToEvent = events.first(where: { $0.id == eventID })
                }
            }
            .onOpenURL { url in
                guard url.scheme == "events",
                      url.host == "open",
                      let idString = url.pathComponents.last,
                      let eventID = UUID(uuidString: idString) else { return }
                navigateToEvent = events.first(where: { $0.id == eventID })
            }
        }
    }
}

extension EventsListView {
    //Filtering options specific to the View
    
    var filteredEvents: [Event] {
        switch filterMode {
        case .all: return events
        case .events: return events.filter { !$0.isBirthday }
        case .birthdays: return events.filter { $0.isBirthday }
        }
    }
    
    // Sort by the next upcoming occurrence date for consistent ordering across categories.
    var sortedFilteredEvents: [Event] {
        filteredEvents.sorted { lhs, rhs in
            let lhsNext = lhs.nextDate
            let rhsNext = rhs.nextDate
            
            if lhsNext != rhsNext {
                return lhsNext < rhsNext
            }
            if lhs.priority != rhs.priority {
                return lhs.priority.rawValue > rhs.priority.rawValue
            }
            if lhs.name.localizedCaseInsensitiveCompare(rhs.name) != .orderedSame {
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }
    
    var todaysEvents: [Event] {
        sortedFilteredEvents.filter { $0.isToday }
    }
    
    var upcomingEvents: [Event] {
        sortedFilteredEvents.filter { $0.isUpcoming && !$0.isToday }
    }
    
    var pastCountdowns: [Event] {
        sortedFilteredEvents.filter { $0.isPast }
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
    func settingsButton() -> some View {
        Button {
            isShowingSettings = true
        } label: {
            Label(Strings.GeneralStrings.options, systemImage: "gear")
                .labelStyle(.iconOnly)
                .background(Color.clear)
        }
    }
    
    @ViewBuilder
    func deletePastEventsView() -> some View {
        Button {
            isConfirmingDelete = true
        } label: {
            Image(systemName: "trash")
                .font(.system(size: 14))
                .foregroundStyle(.red)
        }
        .transition(.opacity.combined(with: .scale))
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
    
    // MARK: - Bottom Bar
    @ViewBuilder
    func bottomBar() -> some View {
        HStack {
            Spacer()
            
            if #available(iOS 26.0, *) {
                Picker("Filter", selection: $filterMode.animation()) {
                    ForEach(EventFilterMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .glassEffect(.clear.interactive())
//                .glassEffect(.regular.interactive())
//                .frame(maxWidth: 220)
                .frame(maxWidth: .infinity)
                .controlSize(.large)
                .padding(.leading)
//                .padding(.top)

            } else {
                Picker("Filter", selection: $filterMode.animation()) {
                    ForEach(EventFilterMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                .frame(maxWidth: 220)
            }
            
            Spacer()
            
            floatingAddEventButton()
        }
        .padding(.bottom, 10)
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
//                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
                .glassEffect(.regular.interactive())
//                .glassEffect(.clear.interactive())
                .matchedTransitionSource(id: "addEventButton", in: eventsNamespace)
                .scaleEffect(0.9)
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
            }
        }
        .allowsHitTesting(!isShowingAddSheet)
    }
}
