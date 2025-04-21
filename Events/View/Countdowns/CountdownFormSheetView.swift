//
//  CountdownFormSheetView.swift
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
    var existingCountdown: CountdownVM?
    
    @State private var formData: CountdownFormData
    @State private var photoItem: PhotosPickerItem?
    @State private var showDeleteConfirmation = false
    @State private var isShowingEmojiPicker = false

    init(existingCountdown: CountdownVM? = nil, navigateToRoot: Binding<Bool> = .constant(false)) {
        self.existingCountdown = existingCountdown
        self._navigateToRoot = navigateToRoot
        self._formData = State(initialValue: CountdownFormData(from: existingCountdown))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(Strings.CountdownForm.basicsSection)) {
                    TextField(Strings.CountdownForm.name, text: $formData.name)
                    TextField(Strings.CountdownForm.description, text: $formData.description)
                    emojiButton()
                }

                Section(header: Text(Strings.CountdownForm.priorityColorSection)) {
                    priorityPicker()
                    ColorPicker(Strings.CountdownForm.color, selection: $formData.color)
                }

                Section(header: Text(Strings.CountdownForm.dateSection)) {
                    DatePicker(Strings.CountdownForm.selectDate, selection: $formData.date, in: Date()..., displayedComponents: .date)
                }

                Section(header: Text(Strings.CountdownForm.repeatSection)) {
                    repeatFrequencyPicker()
                }

                Section(header: Text(Strings.CountdownForm.photoSection)) {
                    photoPicker()
                }

                if existingCountdown != nil {
                    deleteSection()
                }
            }
            .confirmationDialog(Strings.CountdownForm.deleteConfirmTitle,
                                isPresented: $showDeleteConfirmation,
                                titleVisibility: .visible) {
                deleteCountdownButton()
                Button(Strings.CountdownForm.cancel, role: .cancel) {}
            }
            .navigationTitle(existingCountdown == nil ? Strings.CountdownForm.newTitle : Strings.CountdownForm.editTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.CountdownForm.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.CountdownForm.save) {
                        viewModel.saveCountdown(from: formData, existing: existingCountdown)
                        dismiss()
                    }
                    .disabled(formData.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .accentColor(.primary)
    }
}

private extension CountdownFormSheetView {
    
    @ViewBuilder
    func emojiButton() -> some View {
        Button {
            isShowingEmojiPicker = true
        } label: {
            HStack {
                Text(Strings.CountdownForm.emoji)
                Spacer()
                Text(formData.emoji.isEmpty ? Strings.CountdownForm.defaultEmoji : formData.emoji)
                    .font(.system(size: 24))
            }
        }
        .sheet(isPresented: $isShowingEmojiPicker) {
            NavigationStack {
                EmojiPickerView(selectedEmoji: $formData.emoji)
            }
        }
    }
    
    @ViewBuilder
    func priorityPicker() -> some View {
        Picker(Strings.CountdownForm.priority, selection: $formData.priority) {
            ForEach(Priority.allCases, id: \.self) { priority in
                Text(priority.displayName).tag(priority)
            }
        }
    }

    @ViewBuilder
    func repeatFrequencyPicker() -> some View {
        Picker(Strings.CountdownForm.repeatEvery, selection: $formData.repeatFrequency) {
            ForEach(RepeatFrequency.allCases) { freq in
                Text(freq.rawValue).tag(freq)
            }
        }
    }

    @ViewBuilder
    func photoPicker() -> some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            if let selected = formData.photo {
                Image(uiImage: selected)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Label(Strings.CountdownForm.pickPhoto, systemImage: "photo")
            }
        }
        .onChange(of: photoItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    formData.photo = image
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
                Label(Strings.CountdownForm.delete, systemImage: "trash")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .listRowBackground(Color.red.opacity(0.1))
        }
    }

    @ViewBuilder
    func deleteCountdownButton() -> some View {
        Button(Strings.CountdownForm.deleteConfirm, role: .destructive) {
            if let countdownToDelete = existingCountdown {
                viewModel.deleteCountdown(countdownToDelete)
                dismiss()
                withAnimation {
                    navigateToRoot = true
                }
            }
        }
    }
}

struct CountdownFormData {
    var name: String = ""
    var description: String = ""
    var emoji: String = Strings.CountdownForm.defaultEmoji
    var priority: Priority = .medium
    var date: Date = Date()
    var photo: UIImage? = nil
    var color: Color = Countdown.randomColor()
    var repeatFrequency: RepeatFrequency = .none
    
    init(from countdown: CountdownVM? = nil) {
        if let countdown = countdown {
            name = countdown.name
            description = countdown.description
            emoji = countdown.emoji
            priority = countdown.priority
            date = countdown.date
            photo = countdown.photo
            color = countdown.color
            repeatFrequency = countdown.repeatFrequency
        }
    }
}
