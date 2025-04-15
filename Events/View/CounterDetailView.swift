import SwiftUI
import PhotosUI

struct CounterDetailView: View {
    @Environment(CountdownViewModel.self) private var viewModel
    var countdown: Countdown

    @Namespace private var imageNamespace
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var image: UIImage? = nil
    @State private var showFullImage: Bool = false
    @State private var dragOffset: CGSize = .zero

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
                        Text("\(countdown.daysLeft) days left \(countdown.emoji)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(countdown.color)
                        
                        Text(countdown.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .lineLimit(3)
                        
                        if !countdown.description.isEmpty {
                            Text(countdown.description)
                                .font(.body)
                                .foregroundColor(.secondary)
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
                        }
                        
                        PhotosPicker("Choose a Photo", selection: $selectedItem, matching: .images)
                            .font(.body)
                            .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onAppear {
                image = countdown.photo
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
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showFullImage = false
                            }
                        }
                        .zIndex(2)
                }
            }
        }
        .navigationTitle("Countdown Detail")
        .navigationBarTitleDisplayMode(.inline)
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
