import SwiftUI
import PhotosUI
import UIKit

struct CounterDetailView: View {
    @Environment(CountdownViewModel.self) private var viewModel
    var countdown: Countdown
    @State private var isPresentingEdit = false
    @State private var selectedMode: TimeDisplayMode = UserDefaults.standard.savedDisplayMode
    @Environment(\.presentationMode) private var presentationMode

    @Namespace private var imageNamespace
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
            LinearGradient(
                gradient: Gradient(colors: [countdown.color.opacity(0.2), .clear]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("\(viewModel.formattedTimeRemaining(for: countdown)) left \(countdown.emoji)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(countdown.color)
                            .contentTransition(.numericText())
                            .animation(.default, value: viewModel.formattedTimeRemaining(for: countdown))

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
                        .padding(.bottom, 8)
                        
                        Text(countdown.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .lineLimit(3)
                        
                        if countdown.repeatFrequency != .none {
                            Text("Repeats \(countdown.repeatFrequency.rawValue.lowercased())")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .transition(.opacity)
                        }
                        
                        // Editable description section
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
                                if countdown.description.isEmpty {
                                    Text("Tap to add a description...")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .italic()
                                        .onTapGesture {
                                            editedDescription = countdown.description
                                            withAnimation(.easeInOut(duration: 0.25)) {
                                                isEditingDescription = true
                                            }
                                        }
                                } else {
                                    Text(countdown.description)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .onTapGesture {
                                            editedDescription = countdown.description
                                            withAnimation(.easeInOut(duration: 0.25)) {
                                                isEditingDescription = true
                                            }
                                        }
                                }
                            }
                        }
                        
                        // 🌟 Priority Menu
                        HStack(spacing: 8) {
                            Text("Priority:")
                                .fontWeight(.medium)
                            
                            Menu {
                                ForEach(Priority.allCases, id: \.self) { priority in
                                    Button(priority.displayName) {
                                        viewModel.updatePriority(for: countdown.id, to: priority)
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
                        
                        // 📸 Tappable Image with matchedGeometryEffect
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
                        
                        PhotosPicker("Choose a Photo", selection: $selectedItem, matching: .images)
                            .font(.body)
                            .padding(.top, 8)
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
                editedDescription = countdown.description
                selectedMode = UserDefaults.standard.savedDisplayMode
                viewModel.selectedDisplayMode = selectedMode
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        image = uiImage
                        viewModel.updatePhoto(for: countdown.id, image: uiImage)
                    }
                }
            }
            
            // 🖼 Fullscreen overlay with glassy blur + fast transition
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
        .onTapGesture {
            if isEditingDescription {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isEditingDescription = false
                    isDescriptionFocused = false
                    viewModel.updateDescription(for: countdown.id, description: editedDescription)
                }
            }
        }
        .navigationTitle("Countdown Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    isPresentingEdit = true
                }
            }
        }
        .fullScreenCover(isPresented: $isPresentingEdit) {
            CountdownFormView(existingCountdown: countdown, navigateToRoot: $shouldNavigateToRoot)
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
    
    // Share functionality
    func shareCountdown() {
        // Create formatted text for sharing
        let shareText = """
        🎯 Countdown: \(countdown.name)
        ⏱ \(countdown.daysLeft) days left \(countdown.emoji)
        🔔 Priority: \(countdown.priority.displayName)
        
        \(countdown.description)
        
        Shared from my Countdown App
        """
        
        // Items to share
        var itemsToShare: [Any] = [shareText]
        
        // Add image if available
        if let shareImage = image ?? countdown.photo {
            itemsToShare.append(shareImage)
        }
        
        // Create and present the activity view controller
        let activityViewController = UIActivityViewController(
            activityItems: itemsToShare,
            applicationActivities: nil
        )
        
        // Present the activity view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        // Find the top-most presented view controller
        var topController = rootViewController
        while let presenter = topController.presentedViewController {
            topController = presenter
        }
        
        // For iPad, set the popover presentation controller
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = topController.view
            popover.sourceRect = CGRect(x: topController.view.bounds.midX, y: topController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        topController.present(activityViewController, animated: true)
    }
}

// Extension for CountdownViewModel to add updateDescription functionality
extension CountdownViewModel {
    func updateDescription(for id: UUID, description: String) {
        if let index = countdowns.firstIndex(where: { $0.id == id }) {
            countdowns[index].description = description
        }
    }
}

import SwiftUI

struct VisualEffectBlur: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemUltraThinMaterial

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

