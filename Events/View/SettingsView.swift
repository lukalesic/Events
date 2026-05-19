import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDisplayMode: TimeDisplayMode = UserDefaults.standard.savedDisplayMode
    @State private var gridState: GridState = UserDefaults.standard.savedGridState
    
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
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onChange(of: selectedDisplayMode) { _, newValue in
                UserDefaults.standard.savedDisplayMode = newValue
            }
            .onChange(of: gridState) { _, newValue in
                UserDefaults.standard.savedGridState = newValue
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
