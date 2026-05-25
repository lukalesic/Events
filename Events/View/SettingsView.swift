import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var events: [Event]
    @State private var selectedDisplayMode: TimeDisplayMode = UserDefaults.standard.savedDisplayMode
    @State private var gridState: GridState = UserDefaults.standard.savedGridState
    @State private var remind1DayBefore: Bool = UserDefaults.standard.remind1DayBefore
    @State private var remind3DaysBefore: Bool = UserDefaults.standard.remind3DaysBefore
    @State private var defaultNotificationTime: Date = {
        var components = DateComponents()
        components.hour = UserDefaults.standard.defaultNotificationHour
        components.minute = UserDefaults.standard.defaultNotificationMinute
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 40) {
                        Spacer()
                        layoutOption(icon: "list.bullet", label: "List", state: .rows)
                        layoutOption(icon: "square.grid.2x2", label: "Grid", state: .grid)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                } header: {
                    Text("Event Layout")
                }
                
                Section {
                    HStack {
                        Label("Display Time Left as", systemImage: "clock")
                        
                        Spacer()
                        
                        Picker("", selection: $selectedDisplayMode) {
                            ForEach(TimeDisplayMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.gray)
                    }
                } header: {
                    Text("Display")
                } footer: {
                    Text("Choose how countdowns display time by default. \"Automatic\" adapts based on how far away the event is.")
                }
                
                Section {
                    DatePicker("Default Alert Time", selection: $defaultNotificationTime, displayedComponents: .hourAndMinute)
                    
                    Toggle("Remind 1 Day Before", isOn: $remind1DayBefore)
                    Toggle("Remind 3 Days Before", isOn: $remind3DaysBefore)
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Default alert time is used for events without a specific time. Extra reminders will notify you ahead of each event.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                CloseButton {
                    dismiss()
                }
            }
            .onChange(of: selectedDisplayMode) { _, newValue in
                UserDefaults.standard.savedDisplayMode = newValue
            }
            .onChange(of: gridState) { _, newValue in
                UserDefaults.standard.savedGridState = newValue
            }
            .onChange(of: remind1DayBefore) { _, newValue in
                UserDefaults.standard.remind1DayBefore = newValue
                NotificationManager.shared.rescheduleAllNotifications(for: events)
            }
            .onChange(of: remind3DaysBefore) { _, newValue in
                UserDefaults.standard.remind3DaysBefore = newValue
                NotificationManager.shared.rescheduleAllNotifications(for: events)
            }
            .onChange(of: defaultNotificationTime) { _, newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                UserDefaults.standard.defaultNotificationHour = components.hour ?? 10
                UserDefaults.standard.defaultNotificationMinute = components.minute ?? 0
                NotificationManager.shared.rescheduleAllNotifications(for: events)
            }
        }
    }
    
    private func layoutOption(icon: String, label: String, state: GridState) -> some View {
        let isSelected = gridState == state
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                gridState = state
            }
        } label: {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .frame(width: 60, height: 50)
                
                Text(label)
                    .font(.caption)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.gray.opacity(0.3))
            }
        }
        .buttonStyle(.plain)
    }
}
