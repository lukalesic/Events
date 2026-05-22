//
//  EventFormSheetView.swift
//  Events
//
//  Created by Luka Lešić on 20.04.25.
//

import SwiftUI
import _PhotosUI_SwiftUI

struct EventEditSheet: View {
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
                // MARK: - Basics
                Section {
                    TextField(Strings.EventFormStrings.name, text: $formData.name)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    TextField(Strings.EventFormStrings.description, text: $formData.description)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } header: {
                    Text("Basics")
                }
                
                // MARK: - Date
                Section {
                    DatePicker(Strings.EventFormStrings.selectDate, selection: $formData.date, in: Date()..., displayedComponents: formData.includesTime ? [.date, .hourAndMinute] : .date)
                    Toggle("Includes Time", isOn: $formData.includesTime)
                } header: {
                    Text(Strings.EventFormStrings.dateSection)
                }

                // MARK: - Color & Emoji
                Section {
                    HStack(spacing: 16) {
                        // Color
                        VStack(spacing: 8) {
                            Text("Color")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            ColorPicker("", selection: $formData.color)
                                .labelsHidden()
                                .onChange(of: formData.color) { _, newColor in
                                    formData.color = newColor.clamped()
                                }
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        
                        Divider()
                        
                        // Emoji
                        VStack(spacing: 8) {
                            Text("Emoji")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(formData.emoji.isEmpty ? Strings.EventFormStrings.defaultEmoji : formData.emoji)
                                .font(.system(size: 28))
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isShowingEmojiPicker = true
                        }
                    }
                    .padding(.vertical, 1)
                }
                .sheet(isPresented: $isShowingEmojiPicker) {
                    NavigationStack {
                        EmojiPickerView(selectedEmoji: $formData.emoji)
                    }
                }

                // MARK: - Repeat
                Section {
                    priorityPicker()
                    repeatFrequencyPicker()
                } header: {
                    Text(Strings.EventFormStrings.repeatSection)
                }

                // MARK: - Photo
                Section {
                    photoPicker()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                } header: {
                    Text("Photo")
                }

                if event != nil {
                    deleteSection()
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle(event == nil ? Strings.EventFormStrings.newTitle : Strings.EventFormStrings.editTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.EventFormStrings.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if #available(iOS 26.0, *) {
                        Button(role: .confirm) {
                            viewModel.save(from: formData, existing: event)
                            dismiss()
                        }
                        .disabled(formData.name.trimmingCharacters(in: .whitespaces).isEmpty)
                    } else {
                        Button(Strings.EventFormStrings.save) {
                            viewModel.save(from: formData, existing: event)
                            dismiss()
                        }
                        .disabled(formData.name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
        .accentColor(.primary)
    }
}

private extension EventEditSheet {
    
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
        Picker(Strings.EventFormStrings.repeatText, selection: $formData.repeatFrequency) {
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
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text(Strings.EventFormStrings.pickPhoto)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 150)
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .buttonStyle(.plain)
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
            DeleteButtonWithDialog(event: event, showDeleteConfirmation: $showDeleteConfirmation, navigateToRoot: $navigateToRoot)
                .listRowBackground(Color.clear)
        }
    }
}

struct DeleteButtonWithDialog: View {
    var event: Event?
    @Binding var showDeleteConfirmation: Bool
    @Binding var navigateToRoot: Bool
    @Environment(EventViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            if #available(iOS 26.0, *) {
                Label(Strings.EventFormStrings.delete, systemImage: "trash")
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical)
                    .glassEffect(.clear.tint(.red).interactive())
            } else {
                Label(Strings.EventFormStrings.delete, systemImage: "trash")
                    .padding()
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(15)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .confirmationDialog(Strings.EventFormStrings.deleteConfirmTitle,
                            isPresented: $showDeleteConfirmation,
                            titleVisibility: .visible) {
            Button(Strings.EventFormStrings.deleteConfirm, role: .destructive) {
                if let eventToDelete = event {
                    viewModel.delete(eventToDelete)
                    dismiss()
                    withAnimation {
                        navigateToRoot = true
                    }
                }
            }
            Button(Strings.EventFormStrings.cancel, role: .cancel) {}
        }
    }
}

struct EventFormData {
    var name: String = ""
    var description: String = ""
    var emoji: String = Strings.EventFormStrings.defaultEmoji
    var priority: EventPriority = .medium
    var date: Date = Date()
    var includesTime: Bool = false
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
            includesTime = countdown.includesTime
            photo = countdown.photo
            color = countdown.color
            repeatFrequency = countdown.repeatFrequency
        }
    }
}
