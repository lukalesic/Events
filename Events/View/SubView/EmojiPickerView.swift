//
//  EmojiPickerView.swift
//  Events
//
//  Created by Luka Lešić on 20.04.25.
//

import SwiftUI

struct EmojiPickerView: View {
    @Binding var selectedEmoji: String
    @Environment(\.dismiss) private var dismiss

    // Grouped emoji dictionary
    private let emojiSections: [(title: String, icon: String, emojis: [String])] = [
        ("Countdown", "🗓", ["📅", "📆", "🗓", "⏰", "🕰", "🧭", "⏳", "⌛️"]),
        ("Celebration", "🎉", ["🎉", "🎊", "🎈", "🎂", "🍰", "🎁", "🥳", "🪅"]),
        ("Emotions & Vibes", "❤️", ["💖", "❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "😊", "😍", "🥰", "😎", "🤩", "😭", "😇", "😜", "🤪", "😅"]),
        ("Nature & Weather", "🌍", ["🌟", "🌈", "🌞", "🌙", "⭐️", "🔥", "❄️", "🍁", "🌸", "🌼"]),
        ("Travel & Adventure", "✈️", ["✈️", "🚗", "🗺", "🏕", "🏝", "🏖", "🗽", "🗻", "🎡"]),
        ("Fun & Hobbies", "🎵", ["🎵", "🎶", "🎤", "📸", "🎬", "🖌", "🎮", "🧩", "🧵", "🪩"]),
        ("Goals & Motivation", "🏆", ["🏆", "🥇", "🎯", "🏅", "👑", "💪", "📈", "🚀"]),
        ("Holidays & Seasons", "🎄", ["🎄", "🎃", "🕎", "🪔", "🧧", "🎑", "🎍", "🎐"])
    ]

    private let columns = Array(repeating: GridItem(.flexible()), count: 6)

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(emojiSections, id: \.title) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(section.icon) \(section.title)")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.bottom, 5)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(section.emojis, id: \.self) { emoji in
                                Text(emoji)
                                    .font(.system(size: 28))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .padding(6)
                                    .background(selectedEmoji == emoji ? Color.accentColor.opacity(0.3) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .onTapGesture {
                                        selectedEmoji = emoji
                                        dismiss()
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.top)
        }
        .navigationTitle("Pick an Emoji")
    }
}
