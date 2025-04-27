//
//  ContentView.swift
//  Events
//
//  Created by Luka Lešić on 23.03.25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var countdownViewModel: EventViewModel?
    
    var body: some View {
        Group {
            if let viewModel = countdownViewModel {
                EventsListView()
                    .environment(viewModel)
            } else {
                ProgressView("Loading...")
            }
        }
        .onAppear {
            countdownViewModel = EventViewModel(modelContext: modelContext)
        }
    }
}
