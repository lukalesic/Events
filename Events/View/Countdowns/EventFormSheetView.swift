//
//  EventFormSheetView.swift
//  Events
//
//  Created by Luka Lešić on 20.04.25.
//

import SwiftUI
import _PhotosUI_SwiftUI

struct EventFormSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(EventViewModel.self) private var viewModel
    
    @Binding var navigateToRoot: Bool
    var event: Event?
    
    @State private var formData: EventFormData
    @State private var photoItem: PhotosPickerItem?
    @State private var showDeleteConfirmation = false
    @State private var isShowingEmojiPicker = false

    init(event: Event? = nil, navigateToRoot: Binding<Bool> = .constant(false)) {
        self.event = event
        self._navigateToRoot = navigateToRoot
        self._formData = State(initialValue: EventFormData(from: event))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(Strings.EventFormStrings.basicsSection)) {
                    TextField(Strings.EventFormStrings.name, text: $formData.name)
                    TextField(Strings.EventFormStrings.description, text: $formData.description)
                    emojiButton()
                }

                Section(header: Text(Strings.EventFormStrings.priorityColorSection)) {
                    priorityPicker()
                    ColorPicker(Strings.EventFormStrings.color, selection: $formData.color)
                }

                Section(header: Text(Strings.EventFormStrings.dateSection)) {
                    DatePicker(Strings.EventFormStrings.selectDate, selection: $formData.date, in: Date()..., displayedComponents: .date)
                }

                Section(header: Text(Strings.EventFormStrings.repeatSection)) {
                    repeatFrequencyPicker()
                }

                Section(header: Text(Strings.EventFormStrings.photoSection)) {
                    photoPicker()
                }

                if event != nil {
                    deleteSection()
                }
            }
            .confirmationDialog(Strings.EventFormStrings.deleteConfirmTitle,
                                isPresented: $showDeleteConfirmation,
                                titleVisibility: .visible) {
                deleteButton()
                Button(Strings.EventFormStrings.cancel, role: .cancel) {}
            }
            .navigationTitle(event == nil ? Strings.EventFormStrings.newTitle : Strings.EventFormStrings.editTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.EventFormStrings.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.EventFormStrings.save) {
                        viewModel.save(from: formData, existing: event)
                        dismiss()
                    }
                    .disabled(formData.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .accentColor(.primary)
    }
}

private extension EventFormSheetView {
    
    @ViewBuilder
    func emojiButton() -> some View {
        Button {
            isShowingEmojiPicker = true
        } label: {
            HStack {
                Text(Strings.EventFormStrings.emoji)
                Spacer()
                Text(formData.emoji.isEmpty ? Strings.EventFormStrings.defaultEmoji : formData.emoji)
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
        Picker(Strings.EventFormStrings.priority, selection: $formData.priority) {
            ForEach(EventPriority.allCases, id: \.self) { priority in
                Text(priority.displayName).tag(priority)
            }
        }
    }

    @ViewBuilder
    func repeatFrequencyPicker() -> some View {
        Picker(Strings.EventFormStrings.repeatEvery, selection: $formData.repeatFrequency) {
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
                Label(Strings.EventFormStrings.pickPhoto, systemImage: "photo")
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
                Label(Strings.EventFormStrings.delete, systemImage: "trash")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .listRowBackground(Color.red.opacity(0.1))
        }
    }

    @ViewBuilder
    func deleteButton() -> some View {
        Button(Strings.EventFormStrings.deleteConfirm, role: .destructive) {
            if let eventToDelete = event {
                viewModel.delete(eventToDelete)
                dismiss()
                withAnimation {
                    navigateToRoot = true
                }
            }
        }
    }
}

struct EventFormData {
    var name: String = ""
    var description: String = ""
    var emoji: String = Strings.EventFormStrings.defaultEmoji
    var priority: EventPriority = .medium
    var date: Date = Date()
    var photo: UIImage? = nil
    var color: Color = Event.randomColor()
    var repeatFrequency: RepeatFrequency = .none
    
    init(from countdown: Event? = nil) {
        if let countdown = countdown {
            name = countdown.name
            description = countdown.descriptionText
            emoji = countdown.emoji
            priority = countdown.priority
            date = countdown.date
            photo = countdown.photo
            color = countdown.color
            repeatFrequency = countdown.repeatFrequency
        }
    }
}
