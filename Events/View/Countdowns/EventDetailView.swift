import SwiftUI
import PhotosUI
import UIKit

struct EventDetailView: View {
    @Environment(EventViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) private var presentationMode
    @Namespace private var imageNamespace
    
    var event: Countdown
    
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
                    VStack(alignment: .leading, spacing: 16) {
                        timeRemainingLabel()
                        
                        timeDisplayModePicker()
                            .padding(.bottom, 8)
                        
                        eventName()
                        
                        if event.repeatFrequency != .none {
                            repeatLabel()
                        }
                        
                        descriptionSection()
                        
                        priorityMenu()
                        
                        imageView()
                        
                        photoPickerButton()
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
        .navigationTitle(Strings.EventDetailViewStrings.eventDetails)
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
        .fullScreenCover(isPresented: $isPresentingEdit) {
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
            gradient: Gradient(colors: [event.color.opacity(0.25), .clear]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    @ViewBuilder
    func timeRemainingLabel() -> some View {
        let timeString = viewModel.formattedTimeRemaining(for: event)
        let isInPast = Calendar.current.startOfDay(for: event.date) < Calendar.current.startOfDay(for: .now)

        Text("\(timeString) \(event.emoji)")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(event.color)
            .contentTransition(.numericText())
            .animation(.default, value: timeString)
    }
    
    @ViewBuilder
    func timeDisplayModePicker() -> some View {
        Picker(Strings.GeneralStrings.pickerDisplayMode, selection: $selectedMode) {
            ForEach(TimeDisplayMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedMode) {
            viewModel.selectedDisplayMode = selectedMode
            UserDefaults.standard.savedDisplayMode = selectedMode
        }
    }
    
    
    @ViewBuilder
    func eventName() -> some View {
        Text(event.name)
            .font(.title2)
            .fontWeight(.semibold)
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
    func descriptionSection() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if isEditingDescription {
                TextField(Strings.GeneralStrings.description, text: $editedDescription, axis: .vertical)
                    .font(.body)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .focused($isDescriptionFocused)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .onAppear {
                        isDescriptionFocused = true
                    }
            } else {
                if event.descriptionText.isEmpty {
                    Text(Strings.EventDetailViewStrings.addDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .italic()
                        .onTapGesture {
                            editedDescription = event.descriptionText
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isEditingDescription = true
                            }
                        }
                } else {
                    Text(event.descriptionText)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .onTapGesture {
                            editedDescription = event.descriptionText
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isEditingDescription = true
                            }
                        }
                }
            }
        }
    }
    
    @ViewBuilder
    func priorityMenu() -> some View {
        HStack(spacing: 8) {
            Text(Strings.EventDetailViewStrings.priority)
                .fontWeight(.medium)
            
            Menu {
                ForEach(EventPriority.allCases, id: \.self) { priority in
                    Button(priority.displayName) {
                        viewModel.updatePriority(for: event, to: priority)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(event.priority.displayName)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
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
    func imageView() -> some View {
        if let image = image ?? event.photo {
            // Only apply matchedGeometryEffect when not showing fullscreen
            if !showFullImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .cornerRadius(12)
                    .contentShape(Rectangle())
                    .matchedGeometryEffect(id: "image", in: imageNamespace)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                            showFullImage = true
                        }
                    }
            } else {
                // Placeholder with same dimensions but invisible
                Color.clear
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    
    @ViewBuilder
    func photoPickerButton() -> some View {
        PhotosPicker("Choose a Photo", selection: $selectedItem, matching: .images)
            .font(.body)
            .padding(.top, 8)
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
