import SwiftUI

struct CounterDetailView: View {
    @Environment(CountdownViewModel.self) private var viewModel
    var countdown: Countdown

    var body: some View {
        ZStack {
            // 🌈 Gradient in the background
            LinearGradient(
                gradient: Gradient(colors: [countdown.color.opacity(0.5), .clear]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // 🔥 Emoji at the top
                    HStack {
                        Text(countdown.emoji)
                            .font(.system(size: 64))
                            .padding(.leading, 24)
                        Spacer()
                    }
                    .padding(.top, 24)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("\(countdown.daysLeft) days left")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(countdown.color)

                        Text(countdown.name)
                            .font(.title2)
                            .fontWeight(.semibold)

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

                        // TODO: Photo section, etc.
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Countdown Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}
