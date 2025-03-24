//
//  CountdownView.swift
//  Events
//
//  Created by Luka Lešić on 23.03.25.
//

import Foundation
import SwiftUI
import Observation

struct CountdownView: View {
    @Environment(CountdownViewModel.self) private var viewModel
    @Namespace private var countdowns
    
    @State private var columnCount: Int = 2
    
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible()), count: columnCount)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
//                VStack {
//                    LinearGradient(
//                        gradient: Gradient(colors: [Color.red.opacity(0.6), Color.clear]),
//                        startPoint: .top,
//                        endPoint: .bottom
//                    )
//                    .ignoresSafeArea()
//                    .frame(height: 50)
//                    .frame(maxWidth: .infinity)
//                    
//                    Spacer()
//                }
                VStack(spacing: 0) {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.countdowns) { countdown in
                                NavigationLink {
                                    CounterDetailView(countdown: countdown)
                                        .navigationTransition(.zoom(sourceID: countdown.id, in: countdowns))

                                } label: {
                                    CounterBlockView(countdown: countdown)
                                        .matchedTransitionSource(id: countdown.id, in: countdowns)
                                }
                            }
                        }
                        .padding()
                        .animation(.easeInOut, value: columnCount)
                    }
                }
                .navigationTitle("Countdowns")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            columnCount = columnCount == 1 ? 2 : columnCount == 2 ? 3 : 1
                        }) {
                            Image(systemName: "square.grid.2x2")
//                                .tint(.red)
                                .accentColor(.accentColor)
                        }
                    }
                }
            }
        }
    }
}
