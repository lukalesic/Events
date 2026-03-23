import SwiftUI
import PhotosUI
import UIKit

struct EventDetailView: View {
    @Environment(EventViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) private var presentationMode
    @Namespace private var imageNamespace
    @State private var isColorPickerExpanded = false
    @State private var isShowingEmojiPicker = false
    @State private var animatePulse = false
    @State private var showCalendarAccessAlert = false
    @State private var isInCalendar = false
    @State private var showReAddAlert = false
    @State private var showDeleteConfirmation = false
    
    private var predefinedColors: [Color] {
        [
            .green,
            .red,
            .blue,
            .purple,
            .yellow,
        ]
    }
    
    var event: Event
    
    @State private var isPresentingEdit = false
    @State private var selectedMode: TimeDisplayMode = UserDefaults.standard.savedDisplayMode
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var image: UIImage? = nil
    @State private var showFullImage: Bool = false
    @State private var dragOffset: CGSize = .zero
    
    @State private var shouldNavigateToRoot = false
    
    // States for description editing
    @State private var isEditingDescription: Bool = false
    @State private var editedDescription: String = ""
    @FocusState private var isDescriptionFocused: Bool
    
    private var textColor: Color {
        (image ?? event.photo) != nil ? .white : .black
    }
    
    var body: some View {
        ZStack {
            backgroundBlurView()

            ZStack(alignment: .top) {
                // 1. Image as background header
                imageHeaderView()

                ScrollView {
                    // 2. Content overlays image, starts below header
                    VStack(alignment: .center, spacing: 20) {
                        Spacer().frame(height: 160) // Height of image header
                        if #available(iOS 26.0, *) {
                            eventHeaderView()
                            .glassEffect(.clear.tint(.black.opacity(0.0)))
                        } else {
                            eventHeaderView()
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .foregroundStyle(.gray.opacity(0.2))
                            )
                        }
                        
                        timeRemainingLabel()
                        timeDisplayModeMenu()
                        priorityMenu()
                        colorAndEmojiRow()
                            .scaleEffect(0.84)
                        addToCalendar()
                        
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                }
                
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onAppear {
                image = event.photo
                editedDescription = event.descriptionText
                selectedMode = UserDefaults.standard.savedDisplayMode
                viewModel.selectedDisplayMode = selectedMode
            }
            .alert("Calendar Access Denied", isPresented: $showCalendarAccessAlert) {
                Button("Open Settings") {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("To add events to your calendar, please allow access in Settings.")
            }
            .alert("This event is already in your calendar. Do you want to re-add it?", isPresented: $showReAddAlert) {
                Button("Yes", role: .destructive) {
                    viewModel.addToCalendar(event,
                                            onSuccess: {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        withAnimation(.easeOut(duration: 0.3)) {
                            animatePulse = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            animatePulse = false
                        }
                    },
                                            onFailure: {
                        showCalendarAccessAlert = true
                    })
                }
                Button("No", role: .cancel) {}
            }
            
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        image = uiImage
                        // Update directly on the SwiftData model
                        event.photo = uiImage
                        try? modelContext.save()
                    }
                }
            }
            
            fullscreenImageOverlay()
        }
        .onTapGesture {
            if isEditingDescription {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isEditingDescription = false
                    isDescriptionFocused = false
                    event.descriptionText = editedDescription
                    try? modelContext.save()
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                shareButton()
            }
            
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
            }
            
            ToolbarItemGroup(placement: .topBarTrailing) {
                deleteButton()
                editButton()
            }
        }
        .accentColor(.primary)
        .sheet(isPresented: $isPresentingEdit) {
            EventFormSheetView(event: event, navigateToRoot: $shouldNavigateToRoot)
        }
        .onChange(of: shouldNavigateToRoot) { navigateToRoot in
            if navigateToRoot {
                withAnimation {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .onTapGesture {
            if isEditingDescription && !isDescriptionFocused {
                isEditingDescription = false
            }
        }
    }
}

    private extension EventDetailView {
        
        @ViewBuilder
        func backgroundBlurView() -> some View {
            if let bgImage = image ?? event.photo {
                GeometryReader { geo in
                    Image(uiImage: bgImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .blur(radius: 55)
                        .scaleEffect(1.3)
                        .brightness(-0.1)
                        .saturation(1.1)
                }
                .ignoresSafeArea()
            } else {
                Color(event.color).opacity(0.18)
                    .ignoresSafeArea()
            }
        }
        
        @ViewBuilder
        func addToCalendar() -> some View {
            VStack {
                if #available(iOS 26.0, *) {
                    addToCalendarViewContent()
                        .glassEffect(.clear)
                } else {
                    addToCalendarViewContent()
                        .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        
        @ViewBuilder
        func eventHeaderView() -> some View {
            VStack(alignment: .center, spacing: 3) {
                eventName()
                eventDescription()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical)
            .padding(.horizontal)
        }
        
        @ViewBuilder
        func addToCalendarViewContent() -> some View {
            Button {
                if event.isAddedToCalendar {
                    showReAddAlert = true
                } else {
                    viewModel.addToCalendar(event,
                                            onSuccess: {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        
                        withAnimation(.easeInOut(duration: 0.3)) {
                            animatePulse = true
                            isInCalendar = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                animatePulse = false
                            }
                        }
                        event.isAddedToCalendar = true
                    },
                                            onFailure: {
                        showCalendarAccessAlert = true
                    })
                }
            } label: {
                Label(event.isAddedToCalendar ? "Added to Calendar" : "Add to Calendar",
                      systemImage: event.isAddedToCalendar ? "checkmark.circle" : "calendar.badge.plus")
                .foregroundColor(textColor)
                .padding(13)
                .scaleEffect(animatePulse ? 1.25 : 1.0)
            }
            
        }
        
        @ViewBuilder
        func editButton() -> some View {
            
            Button {
                isPresentingEdit = true
            } label: {
                Image(systemName: "pencil")
            }
        }
        
        @ViewBuilder
        func deleteButton() -> some View {
            Menu {
                Button(role: .destructive) {
                    viewModel.delete(event)
                    withAnimation {
                        presentationMode.wrappedValue.dismiss()
                    }
                } label: {
                    Label("Delete This Event", systemImage: "trash")
                        .tint(.red)
                }
            } label: {
                Image(systemName: "trash")
                    .tint(.red)
            }
        }
        
        
        @ViewBuilder
        func timeRemainingLabel() -> some View {
            if #available(iOS 26.0, *) {
                timeRemainingLabelContentView()
                    .glassEffect(.clear)
                
            } else {
                timeRemainingLabelContentView()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .foregroundStyle(.gray.opacity(0.2))
                    )
            }
        }
        
        @ViewBuilder
        func timeRemainingLabelContentView() -> some View {
            
            let timeString = viewModel.formattedTimeRemaining(for: event)
            let isInPast = Calendar.current.startOfDay(for: event.date) < Calendar.current.startOfDay(for: .now)
            
            VStack(spacing: 7) {
                Text("\(timeString)")
                    .font(.system(size: 28))
                    .fontWeight(.bold)
                    .foregroundColor(textColor)
                    .contentTransition(.numericText())
                    .multilineTextAlignment(.center)
                    .animation(.default, value: timeString)
                
                if event.includesTime {
                    Text(event.nextDate, style: .date)
                    + Text(" at ")
                    + Text(event.nextDate, style: .time)
                } else {
                    Text(event.nextDate, style: .date)
                }
                
                if event.repeatFrequency != .none {
                    repeatLabel()
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .center)
            .foregroundColor(textColor)
        }
        
        @ViewBuilder
        func timeDisplayModeMenu() -> some View {
            HStack(spacing: 8) {
                Text("Display time as:")
                    .font(.system(size: 18))
                    .fontWeight(.medium)
                    .foregroundColor(textColor)

                Spacer()
                
                Menu {
                    ForEach(TimeDisplayMode.allCases, id: \.self) { mode in
                        Button(mode.rawValue) {
                            viewModel.selectedDisplayMode = mode
                            UserDefaults.standard.savedDisplayMode = mode
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        if #available(iOS 26.0, *) {
                            Text(viewModel.selectedDisplayMode.rawValue)
                                .fixedSize()
                                .padding(.horizontal, 15)
                                .padding(.vertical, 6)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .glassEffect(.clear)
                            
                        } else {
                            Text(viewModel.selectedDisplayMode.rawValue)
                                .fixedSize()
                                .padding(.horizontal, 15)
                                .padding(.vertical, 6)
                                .foregroundColor(textColor)
                                .cornerRadius(8)
                                .background(.gray.opacity(0.2))
                        }
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .contentTransition(.numericText())
                    .animation(.default, value: viewModel.selectedDisplayMode.rawValue)
                }
            }
        }
        
        @ViewBuilder
        func eventName() -> some View {
            Text(event.name)
                .font(.largeTitle)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .foregroundColor(textColor)
                .padding(.horizontal)
                .padding(.vertical, 4)
        }
        
        @ViewBuilder
        func repeatLabel() -> some View {
            Text("Repeats \(event.repeatFrequency.rawValue.lowercased())")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .transition(.opacity)
            
        }
        
        @ViewBuilder
        func eventDescription() -> some View {
            VStack(alignment: .leading, spacing: 4) {
                if !event.descriptionText.isEmpty {
                    Text(event.descriptionText)
                        .font(.system(size: 18))
                        .foregroundColor(textColor)
                        .lineLimit(3)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.85)
                        .padding(.horizontal)
                }
            }
        }
        
        @ViewBuilder
        func priorityMenu() -> some View {
            HStack(spacing: 8) {
                Text(Strings.EventDetailViewStrings.priority)
                    .font(.system(size: 18))
                    .fontWeight(.medium)
                    .foregroundColor(textColor)
                
                Spacer()
                
                Menu {
                    ForEach(EventPriority.allCases, id: \.self) { priority in
                        Button(priority.displayName) {
                            viewModel.updatePriority(for: event, to: priority)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        if #available(iOS 26.0, *) {
                            Text(event.priority.displayName)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 6)
                                .foregroundColor(textColor)
                                .cornerRadius(8)
//                                .glassEffect(.regular.tint(event.color.opacity(0.2)).interactive())
                                .glassEffect(.clear)

                        } else {
                            Text(event.priority.displayName)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 6)
                                .foregroundColor(textColor)
                                .cornerRadius(8)
                                .background(.gray.opacity(0.2))
                        }
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .contentTransition(.numericText())
                    .animation(.default, value: event.priority.displayName)
                    
                }
            }
        }
        
        @ViewBuilder
        func colorAndEmojiRow() -> some View {
            HStack(spacing: 17) {
                // Color bubble
                if #available(iOS 26.0, *) {
                    colorBubbleContent()
                        .glassEffect(.clear.interactive())
                } else {
                    colorBubbleContent()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .foregroundStyle(.gray.opacity(0.2))
                        )
                }
                
                // Emoji bubble
                if !isColorPickerExpanded {
                    if #available(iOS 26.0, *) {
                        emojiBubbleContent()
                            .glassEffect(.clear.interactive())
                            .transition(.opacity.combined(with: .scale))
                    } else {
                        emojiBubbleContent()
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .foregroundStyle(.gray.opacity(0.2))
                            )
                            .transition(.opacity.combined(with: .scale))
                    }
                }
            }
        }
        
        @ViewBuilder
        func colorBubbleContent() -> some View {
            VStack(spacing: 10) {
                Text("Color")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(textColor.opacity(0.7))
                
                HStack(spacing: 10) {
                    if isColorPickerExpanded {
                        ForEach(predefinedColors, id: \.self) { color in
                            colorCircle(color: color)
                                .transition(.scale.combined(with: .opacity))
                                .onTapGesture {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        event.color = color
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            isColorPickerExpanded = false
                                        }
                                    }
                                }
                        }
                    } else {
                        colorCircle(color: event.color)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    isColorPickerExpanded.toggle()
                                }
                            }
                    }
                }
            }
            .padding(.vertical, 14)
//            .padding(.horizontal, 37)
            .frame(maxWidth: .infinity)
        }
        
        @ViewBuilder
        func emojiBubbleContent() -> some View {
            VStack(spacing: 10) {
                Text("Emoji")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(textColor.opacity(0.7))
                
                Button {
                    isShowingEmojiPicker = true
                } label: {
                    Text(event.emoji.isEmpty ? Strings.EventFormStrings.defaultEmoji : event.emoji)
                        .font(.system(size: 32))
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $isShowingEmojiPicker) {
                    NavigationStack {
                        EmojiPickerView(selectedEmoji: Binding(
                            get: { self.event.emoji },
                            set: { newValue in
                                self.event.emoji = newValue
                                try? modelContext.save()
                            }
                        ))
                    }
                }
            }
            .padding(.vertical, 14)
//            .padding(.horizontal, 40)
            .frame(maxWidth: .infinity)
            
        }
        
        @ViewBuilder
        func colorCircle(color: Color) -> some View {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 34, height: 34)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                if event.color == color {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        
        @ViewBuilder
        func imageHeaderView() -> some View {
            ZStack(alignment: .bottom) {
                if let image = image ?? event.photo {
                        // Main header image pinned to the top
                        GeometryReader { geo in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                        }
                        .containerRelativeFrame(.vertical) { size, axis in
                            size * 0.55
                        }
                        .ignoresSafeArea(edges: .top)
                        // Gradient mask: sharp at top, fades to transparent at bottom
                        // so the blurred full-screen background shows through
                        .mask(
                            VStack(spacing: 0) {
                                Color.white
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: .white, location: 0.0),
                                        .init(color: .white.opacity(0.4), location: 0.35),
                                        .init(color: .clear, location: 1.0)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 160)
                            }
                        )
                } else {
                    Rectangle()
                        .fill(event.color.opacity(0.18))
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        
        @ViewBuilder
        func imageView() -> some View {
            VStack {
                if let image = image ?? event.photo {
                    if !showFullImage {
                        
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .containerRelativeFrame(.horizontal) { size, axis in
                                size * 0.9
                            }
                            .containerRelativeFrame(.vertical) { size, axis in
                                size * 0.5
                            }
                            .clipped()
                            .cornerRadius(20)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .contentShape(Rectangle())
                            .matchedGeometryEffect(id: "image", in: imageNamespace)
                            .shadow(radius: 7)
                        
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                    showFullImage = true
                                }
                            }
                    } else {
                        Color.clear
                            .frame(height: 250)
                            .frame(width: 200)
                    }
                } else {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        if #available(iOS 26.0, *) {
                            VStack(spacing: 10) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text("Tap to add image..")
                            }
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                            .padding()
                            .frame(height: 100)
                            .containerRelativeFrame(.horizontal) { size, axis in
                                size * 0.9
                            }
                            .shadow(radius: 7)
                            .glassEffect(.regular.tint(event.color.opacity(0.15)).interactive())
                        } else {
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                VStack(spacing: 10) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Text("Tap to add image..")
                                }
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                                .padding()
                                .frame(height: 100)
                                .containerRelativeFrame(.horizontal) { size, axis in
                                    size * 0.9
                                }
                                .shadow(radius: 7)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(event.color.opacity(0.15))
                                )
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        
        
        @ViewBuilder
        func fullscreenImageOverlay() -> some View {
            if showFullImage, let fullImage = image ?? event.photo {
                ZStack {
                    // 🧊 Frosted glass background
                    VisualEffectBlur()
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .zIndex(1)
                    
                    // Apply matchedGeometryEffect only when showing fullscreen
                    Image(uiImage: fullImage)
                        .resizable()
                        .scaledToFit()
                        .matchedGeometryEffect(id: "image", in: imageNamespace)
                        .background(Color.black.opacity(0.001)) // tap area
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .offset(dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in dragOffset = gesture.translation }
                                .onEnded { gesture in
                                    if abs(gesture.translation.height) > 100 {
                                        withAnimation(.spring(bounce: 0.25)) {
                                            showFullImage = false
                                            dragOffset = .zero
                                        }
                                    } else {
                                        withAnimation(.spring(bounce: 0.25)) {
                                            dragOffset = .zero
                                        }
                                    }
                                }
                        )
                        .onTapGesture {
                            withAnimation(.spring(bounce: 0.25)) {
                                showFullImage = false
                            }
                        }
                        .zIndex(2)
                }
            }
        }
        
        @ViewBuilder
        func shareButton() -> some View {
            Button {
                viewModel.share(event: event, image: image)
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .scaleEffect(0.9)
                    .offset(y: -2.5)
            }
            .accessibilityLabel("Share Countdown")
        }
    }

