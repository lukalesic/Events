import SwiftUI
import PhotosUI
import UIKit

struct EventDetailView: View {
    @Environment(EventViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) private var presentationMode
    @Namespace private var imageNamespace
    
    private var predefinedColors: [Color] {
        [
            .green,
            .red,
            .yellow,
            .blue,
            .purple
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
    
    var body: some View {
        ZStack {
            linearGradient()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 22) {
                        
                        imageView()
                        
                        VStack(alignment: .leading, spacing: 3) {
                            eventName()
                            eventDescription()
                        }
                        
                            timeRemainingLabel()
                        
                            timeDisplayModeMenu()
                        
                        
                        if event.repeatFrequency != .none {
                            repeatLabel()
                        }
                        
                        priorityMenu()
                        
                        colorPickerMenu()
                        
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeInOut(duration: 0.25), value: isEditingDescription)
                    .padding()
                }
                .animation(.default, value: viewModel.formattedTimeRemaining(for: event))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onAppear {
                image = event.photo
                editedDescription = event.descriptionText
                selectedMode = UserDefaults.standard.savedDisplayMode
                viewModel.selectedDisplayMode = selectedMode
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
        .accentColor(.primary)

        .onTapGesture {
            if isEditingDescription {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isEditingDescription = false
                    isDescriptionFocused = false
                    // Update directly on the SwiftData model
                    event.descriptionText = editedDescription
                    try? modelContext.save()
                }
            }
        }
//        .navigationTitle(Strings.EventDetailViewStrings.eventDetails)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(Strings.GeneralStrings.edit) {
                    isPresentingEdit = true
                }
                
                shareButton()
            }
        }
        .tint(event.color)
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
    func linearGradient() -> some View {
        LinearGradient(
            gradient: Gradient(colors: [event.color.opacity(0.35), .clear]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    @ViewBuilder
    func timeRemainingLabel() -> some View {
        let timeString = viewModel.formattedTimeRemaining(for: event)
        let isInPast = Calendar.current.startOfDay(for: event.date) < Calendar.current.startOfDay(for: .now)
        
        VStack {
            
            Text("\(timeString)")
                .font(.system(size: 28))
                .fontWeight(.bold)
                .foregroundColor(event.color)
                .contentTransition(.numericText())
                .multilineTextAlignment(.center)
                .animation(.default, value: timeString)
            
            Text(event.nextDate, style: .date)

        }
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(event.color.opacity(0.2))
        )
    }
    
    @ViewBuilder
    func timeDisplayModeMenu() -> some View {
        Menu {
            ForEach(TimeDisplayMode.allCases, id: \.self) { mode in
                Button {
                    viewModel.selectedDisplayMode = mode
                    UserDefaults.standard.savedDisplayMode = mode
                } label: {
                    Text(mode.rawValue)
                }
            }
        } label: {
            HStack {
                Image(systemName: "chevron.down")
            }
            .font(.title3)
            .foregroundColor(.primary)
            .padding(8)
            .tint(event.color)
            .scaleEffect(0.6)
            .background(
                Circle()
                    .tint(event.color.opacity(0.8))
            )
        }
    }
    
    @ViewBuilder
    func eventName() -> some View {
        Text(event.name)
            .font(.largeTitle)
            .fontWeight(.semibold)
            .multilineTextAlignment(.leading)
            .lineLimit(3)
    }
    
    @ViewBuilder
    func repeatLabel() -> some View {
        Text("Repeats \(event.repeatFrequency.rawValue.lowercased())")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .transition(.opacity)
        
    }
    
    @ViewBuilder
    func eventDescription() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if !event.descriptionText.isEmpty {
                Text(event.descriptionText)
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .onTapGesture {
                        editedDescription = event.descriptionText
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isEditingDescription = true
                        }
                    }
            }
        }
    }
    
    @ViewBuilder
    func priorityMenu() -> some View {
        HStack(spacing: 8) {
            Text(Strings.EventDetailViewStrings.priority)
                .font(.system(size: 18))
                .fontWeight(.medium)
            
            Spacer()
            
            Menu {
                ForEach(EventPriority.allCases, id: \.self) { priority in
                    Button(priority.displayName) {
                        viewModel.updatePriority(for: event, to: priority)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(event.priority.displayName)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 6)
                        .background(event.color.opacity(0.2))
                        .foregroundColor(event.color)
                        .cornerRadius(8)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    @ViewBuilder
    func colorPickerMenu() -> some View {
        HStack() {
            Text("Color:")
                .font(.system(size: 18))
                .fontWeight(.medium)
            
            Spacer()
            
            HStack(spacing: 12) {
                ForEach(predefinedColors, id: \.self) { color in
                    ZStack {
                        Circle()
                            .fill(color)
                            .frame(width: 34, height: 34)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                            )
                            .scaleEffect(event.color == color ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: event.color)
                        
                        if event.color == color {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            event.color = color
                            try? modelContext.save()
                        }
                    }
                }
            }
        }
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
                    VStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)

                        Text("Tap to add image..")
                    }
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(height: 100)
                    .frame(width: 200)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(event.color.opacity(0.15))
                    )
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
