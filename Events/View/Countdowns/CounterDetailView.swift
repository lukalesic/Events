import SwiftUI
import PhotosUI
import UIKit

struct CounterDetailView: View {
    @Environment(CountdownViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) private var presentationMode
    @Namespace private var imageNamespace
    
    var countdown: Countdown
    
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
                        
                        countdownName()
                        
                        if countdown.repeatFrequency != .none {
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
                .animation(.default, value: viewModel.formattedTimeRemaining(for: countdown))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onAppear {
                image = countdown.photo
                editedDescription = countdown.descriptionText
                selectedMode = UserDefaults.standard.savedDisplayMode
                viewModel.selectedDisplayMode = selectedMode
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        image = uiImage
                        // Update directly on the SwiftData model
                        countdown.photo = uiImage
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
                    countdown.descriptionText = editedDescription
                    try? modelContext.save()
                }
            }
        }
        .navigationTitle("Countdown Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button("Edit") {
                    isPresentingEdit = true
                }
                
                shareButton()
            }
        }
        .tint(countdown.color)
        .fullScreenCover(isPresented: $isPresentingEdit) {
            CountdownFormSheetView(existingCountdown: countdown, navigateToRoot: $shouldNavigateToRoot)
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

private extension CounterDetailView {
    
    @ViewBuilder
    func linearGradient() -> some View {
        LinearGradient(
            gradient: Gradient(colors: [countdown.color.opacity(0.25), .clear]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    @ViewBuilder
    func timeRemainingLabel() -> some View {
        let timeString = viewModel.formattedTimeRemaining(for: countdown)
        let isInPast = Calendar.current.startOfDay(for: countdown.date) < Calendar.current.startOfDay(for: .now)

        Text("\(timeString) \(countdown.emoji)")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(countdown.color)
            .contentTransition(.numericText())
            .animation(.default, value: timeString)
            .onAppear {
                print("*DEBUG \(countdown.daysLeft)")
            }
    }
    
    @ViewBuilder
    func timeDisplayModePicker() -> some View {
        Picker("Display Mode", selection: $selectedMode) {
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
    func countdownName() -> some View {
        Text(countdown.name)
            .font(.title2)
            .fontWeight(.semibold)
            .lineLimit(3)
    }
    
    @ViewBuilder
    func repeatLabel() -> some View {
        Text("Repeats \(countdown.repeatFrequency.rawValue.lowercased())")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .transition(.opacity)
        
    }
    
    @ViewBuilder
    func descriptionSection() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if isEditingDescription {
                TextField("Description", text: $editedDescription, axis: .vertical)
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
                if countdown.descriptionText.isEmpty {
                    Text("Tap to add a description...")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .italic()
                        .onTapGesture {
                            editedDescription = countdown.descriptionText
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isEditingDescription = true
                            }
                        }
                } else {
                    Text(countdown.descriptionText)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .onTapGesture {
                            editedDescription = countdown.descriptionText
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
            Text("Priority:")
                .fontWeight(.medium)
            
            Menu {
                ForEach(EventPriority.allCases, id: \.self) { priority in
                    Button(priority.displayName) {
                        viewModel.updatePriority(for: countdown, to: priority)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(countdown.priority.displayName)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(countdown.color.opacity(0.2))
                        .foregroundColor(countdown.color)
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
        if let image = image ?? countdown.photo {
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
        if showFullImage, let fullImage = image ?? countdown.photo {
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
            viewModel.share(countdown: countdown, image: image)
        } label: {
            Image(systemName: "square.and.arrow.up")
                .scaleEffect(0.9)
                .offset(y: -2.5)
        }
        .accessibilityLabel("Share Countdown")
    }
}
