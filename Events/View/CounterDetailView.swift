import SwiftUI
import PhotosUI

struct CounterDetailView: View {
    @Environment(CountdownViewModel.self) private var viewModel
    var countdown: Countdown

    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var image: UIImage? = nil

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

                        // 📸 Photo Display
                        if let image = image ?? countdown.photo {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .cornerRadius(12)
                        }

                        // 📤 Photo Picker
                        PhotosPicker("Choose a Photo", selection: $selectedItem, matching: .images)
                            .font(.body)
                            .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onAppear {
                image = countdown.photo // Load existing image on appear
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
        }
        .navigationTitle("Countdown Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}
