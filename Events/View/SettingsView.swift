import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDisplayMode: TimeDisplayMode = UserDefaults.standard.savedDisplayMode
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Label("Time Display", systemImage: "clock")
                        
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
        }
    }
}
