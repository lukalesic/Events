//
//  CountdownSheetView.swift
//  Events
//
//  Created by Luka Lešić on 20.04.25.
//

import SwiftUI
import _PhotosUI_SwiftUI

struct CountdownFormSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CountdownViewModel.self) private var viewModel
    
    @Binding var navigateToRoot: Bool
    @State private var selectedRepeatFrequency: RepeatFrequency
    
    var existingCountdown: Countdown?
    
    @State private var name: String
    @State private var description: String
    @State private var emoji: String = "📅"
    @State private var selectedPriority: Priority
    @State private var selectedDate: Date
    @State private var selectedPhoto: UIImage?
    @State private var color: Color
    @State private var showDeleteConfirmation = false
    @State private var isShowingEmojiPicker = false
    
    @State private var photoItem: PhotosPickerItem?
    
    init(existingCountdown: Countdown? = nil, navigateToRoot: Binding<Bool> = .constant(false)) {
        self.existingCountdown = existingCountdown
        self._navigateToRoot = navigateToRoot
        _name = State(initialValue: existingCountdown?.name ?? "")
        _description = State(initialValue: existingCountdown?.description ?? "")
        _emoji = State(initialValue: existingCountdown?.emoji ?? "")
        _selectedPriority = State(initialValue: existingCountdown?.priority ?? .medium)
        _selectedDate = State(initialValue: existingCountdown?.date ?? .now)
        _selectedPhoto = State(initialValue: existingCountdown?.photo)
        _color = State(initialValue: existingCountdown?.color ?? Countdown.randomColor())
        _selectedRepeatFrequency = State(initialValue: existingCountdown?.repeatFrequency ?? .none)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basics")) {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description)
                    
                    emojiButton()
                }
                    
                    Section(header: Text("Priority & Color")) {
                        priorityPicker()
                        ColorPicker("Color", selection: $color)
                    }
                    
                    Section(header: Text("Countdown Date")) {
                        DatePicker("Select date",
                                   selection: $selectedDate,
                                   in: Date()..., displayedComponents: .date)
                    }
                    
                    Section(header: Text("Repeat")) {
                        repeatFrequencyPicker()
                    }
                    
                    Section(header: Text("Photo")) {
                        photoPicker()
                    }
                    
                    // Only show if editing an existing countdown
                    if existingCountdown != nil {
                        deleteSection()
                    }
                }
                .confirmationDialog("Are you sure you want to delete this countdown?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                    deleteCountdownButton()
                    
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
                        saveButton()
                    }
                }
            }
        }
    }

private extension CountdownFormSheetView {
    
    @ViewBuilder
    func emojiButton() -> some View {
        Button {
            isShowingEmojiPicker = true
        } label: {
            HStack {
                Text("Emoji")
                Spacer()
                Text(emoji.isEmpty ? "📅" : emoji)
                    .font(.system(size: 24))
            }
        }
        .sheet(isPresented: $isShowingEmojiPicker) {
            NavigationStack {
                EmojiPickerView(selectedEmoji: $emoji)
            }
        }
    }
    
    @ViewBuilder
    func priorityPicker() -> some View {
        Picker("Priority", selection: $selectedPriority) {
            ForEach(Priority.allCases, id: \.self) { priority in
                Text(priority.displayName).tag(priority)
            }
        }
    }
    
    @ViewBuilder
    func repeatFrequencyPicker() -> some View {
        Picker("Repeat Every", selection: $selectedRepeatFrequency) {
            ForEach(RepeatFrequency.allCases) { freq in
                Text(freq.rawValue).tag(freq)
            }
        }
    }
    
    @ViewBuilder
    func photoPicker() -> some View {
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
    
    @ViewBuilder
    func deleteSection() -> some View {
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
    
    @ViewBuilder
    func deleteCountdownButton() -> some View {
        Button("Delete", role: .destructive) {
            if let countdownToDelete = existingCountdown {
                viewModel.deleteCountdown(countdownToDelete)
                dismiss()
                withAnimation {
                    navigateToRoot = true
                }
            }
        }
    }
    
    @ViewBuilder
    func saveButton() -> some View {
        Button("Save") {
            let today = Calendar.current.startOfDay(for: .now)
            let target = Calendar.current.startOfDay(for: selectedDate)
            let newDaysLeft = Calendar.current.dateComponents([.day], from: today, to: target).day ?? 0
            
            let finalEmoji = emoji.isEmpty ? "📅" : emoji

            let updatedCountdown = Countdown(
                id: existingCountdown?.id ?? UUID(),
                color: color,
                daysLeft: newDaysLeft,
                name: name,
                description: description,
                emoji: finalEmoji,
                priority: selectedPriority,
                date: selectedDate,
                photo: selectedPhoto,
                repeatFrequency: selectedRepeatFrequency
            )
            
            if existingCountdown != nil {
                viewModel.updateCountdown(updatedCountdown)
            } else {
                viewModel.addCountdown(updatedCountdown)
            }
            
            dismiss()
        }
        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
    }
    
    
}
