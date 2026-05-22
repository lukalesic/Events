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

    private var predefinedColors: [Color] {
        [.green, .red, .blue, .purple, .yellow, .gray]
    }

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
                    TextField(Strings.EventFormStrings.description, text: $formData.description)
                    emojiButton()
                } header: {
                    Text(Strings.EventFormStrings.basicsSection)
                }


                // MARK: - Color
                Section {
                    HStack(spacing: 12) {
                        ForEach(predefinedColors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.primary, lineWidth: formData.color.roughlyEquals(color) ? 2.5 : 0)
                                )
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        formData.color = color
                                    }
                                }
                        }
                        
                        Divider()
                            .frame(width: 1)
                        
                        ColorPicker("", selection: $formData.color)
                            .labelsHidden()
                            .frame(width: 44, height: 44)
                            .onChange(of: formData.color) { _, newColor in
                                formData.color = newColor.clamped()
                            }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Color")
                }

                
                // MARK: - Date
                Section {
                    Toggle("Includes Time", isOn: $formData.includesTime)
                    DatePicker(Strings.EventFormStrings.selectDate, selection: $formData.date, in: Date()..., displayedComponents: formData.includesTime ? [.date, .hourAndMinute] : .date)
                } header: {
                    Text(Strings.EventFormStrings.dateSection)
                }
                
                // MARK: - Priority
                Section {
                    Picker(Strings.EventFormStrings.priority, selection: $formData.priority) {
                        ForEach(EventPriority.allCases, id: \.self) { priority in
                            Text(priority.displayName).tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text(Strings.EventFormStrings.priorityColorSection)
                }

                // MARK: - Repeat
                Section {
                    repeatFrequencyPicker()
                } header: {
                    Text(Strings.EventFormStrings.repeatSection)
                }

                // MARK: - Photo
                Section {
                    photoPicker()
                } header: {
                    Text(Strings.EventFormStrings.photoSection)
                }

                if event != nil {
                    deleteSection()
                }
            }
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
            DeleteButtonWithDialog(event: event, showDeleteConfirmation: $showDeleteConfirmation, navigateToRoot: $navigateToRoot)
                .listRowBackground(Color.clear)
        }
    }
}

// MARK: - Color comparison helper
private extension Color {
    func roughlyEquals(_ other: Color) -> Bool {
        let lhs = UIColor(self)
        let rhs = UIColor(other)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        lhs.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        rhs.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let threshold: CGFloat = 0.05
        return abs(r1 - r2) < threshold && abs(g1 - g2) < threshold && abs(b1 - b2) < threshold
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
