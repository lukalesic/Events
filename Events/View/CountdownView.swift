import Foundation
import SwiftUI
import Observation
import PhotosUI


struct CountdownView: View {
    @Environment(CountdownViewModel.self) private var viewModel
    @Namespace private var countdowns
    @State private var isShowingAddSheet = false

    @State private var gridState: GridState = .grid

    private var columns: [GridItem] {
        gridState == .grid ? Array(repeating: GridItem(.flexible()), count: 2) : [GridItem(.flexible())]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.countdowns) { countdown in
                                NavigationLink {
                                    CounterDetailView(countdown: countdown)
                                        .navigationTransition(.zoom(sourceID: countdown.id, in: countdowns))
                                } label: {
                                    CounterBlockView(countdown: countdown, gridState: gridState)
                                        .matchedTransitionSource(id: countdown.id, in: countdowns)
                                }
                            }
                        }
                        .padding()
                        .animation(.spring(duration: 0.4, bounce: 0.25), value: gridState)
//                        .animation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.2), value: gridState)
                    }
                }
                .navigationTitle("Countdowns")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            Button(action: {
                                isShowingAddSheet = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                            }

                            Button(action: {
                                gridState = gridState == .grid ? .rows : .grid
                            }) {
                                Image(systemName: gridState == .grid ? "list.bullet" : "square.grid.2x2")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
                .fullScreenCover(isPresented: $isShowingAddSheet) {
                    CountdownFormView()
                }
            }
        }
    }
}

enum GridState {
    case grid
    case rows
}

//TODO NEW FILE
struct CountdownFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CountdownViewModel.self) private var viewModel

    var existingCountdown: Countdown?

    @State private var name: String
    @State private var description: String
    @State private var emoji: String
    @State private var selectedPriority: Priority
    @State private var selectedDate: Date
    @State private var selectedPhoto: UIImage?
    @State private var color: Color
    @State private var showDeleteConfirmation = false
    
    @State private var photoItem: PhotosPickerItem?

    init(existingCountdown: Countdown? = nil) {
        self.existingCountdown = existingCountdown
        _name = State(initialValue: existingCountdown?.name ?? "")
        _description = State(initialValue: existingCountdown?.description ?? "")
        _emoji = State(initialValue: existingCountdown?.emoji ?? "")
        _selectedPriority = State(initialValue: existingCountdown?.priority ?? .medium)
        _selectedDate = State(initialValue: existingCountdown?.date ?? .now)
        _selectedPhoto = State(initialValue: existingCountdown?.photo)
        _color = State(initialValue: existingCountdown?.color ?? Countdown.randomColor())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basics")) {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description)
                    TextField("Emoji", text: $emoji)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .frame(maxWidth: 60)
                }

                Section(header: Text("Priority & Color")) {
                    Picker("Priority", selection: $selectedPriority) {
                        ForEach(Priority.allCases, id: \.self) { priority in
                            Text(priority.displayName).tag(priority)
                        }
                    }
                    ColorPicker("Color", selection: $color)
                }

                Section(header: Text("Countdown Date")) {
                    DatePicker("Select date", selection: $selectedDate, displayedComponents: .date)
                }

                Section(header: Text("Photo (Optional)")) {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        if let selectedPhoto {
                            Image(uiImage: selectedPhoto)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            Label("Pick a Photo", systemImage: "photo")
                        }
                    }
                    .onChange(of: photoItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                selectedPhoto = uiImage
                            }
                        }
                    }
                }
                
                // Only show if editing an existing countdown
                if existingCountdown != nil {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Countdown", systemImage: "trash")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .listRowBackground(Color.red.opacity(0.1))
                    }
                }
            }
            .confirmationDialog("Are you sure you want to delete this countdown?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let countdownToDelete = existingCountdown {
                        viewModel.deleteCountdown(countdownToDelete)
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
            .navigationTitle(existingCountdown == nil ? "New Countdown" : "Edit Countdown")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let today = Calendar.current.startOfDay(for: .now)
                        let target = Calendar.current.startOfDay(for: selectedDate)
                        let newDaysLeft = Calendar.current.dateComponents([.day], from: today, to: target).day ?? 0

                        let updatedCountdown = Countdown(
                            id: existingCountdown?.id ?? UUID(),
                            color: color,
                            daysLeft: newDaysLeft,
                            name: name,
                            description: description,
                            emoji: emoji,
                            priority: selectedPriority,
                            date: selectedDate,
                            photo: selectedPhoto
                        )

                        if existingCountdown != nil {
                            viewModel.updateCountdown(updatedCountdown)
                        } else {
                            viewModel.addCountdown(updatedCountdown)
                        }

                        dismiss()
                    }
                }
            }
        }
    }
}


