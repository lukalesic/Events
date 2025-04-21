import Foundation
import SwiftUI
import Observation
import PhotosUI

struct CountdownView: View {
    @Environment(CountdownViewModel.self) private var viewModel
    @Namespace private var countdowns
    
    @State private var isShowingAddSheet = false
    @State private var gridState: GridState = UserDefaults.standard.savedGridState
    
    private var columns: [GridItem] {
        gridState == .grid ? Array(repeating: GridItem(.flexible()), count: 2) : [GridItem(.flexible())]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.countdowns) { countdown in
                                NavigationLink {
                                    CounterDetailView(countdown: countdown)
                                        .navigationTransition(.zoom(sourceID: countdown.id, in: countdowns))
                                } label: {
                                    CounterBlockView(countdown: countdown, gridState: gridState)
                                        .matchedTransitionSource(id: countdown.id, in: countdowns)
                                }
                            }
                        }
                        .padding()
                        .animation(.spring(response: 0.4,
                                           dampingFraction: 0.75,
                                           blendDuration: 0.2),
                                   value: gridState)
                    }
                }
                .navigationTitle("Countdowns")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            gridButton()
                            addNewButton()
                        }
                    }
                }
                .fullScreenCover(isPresented: $isShowingAddSheet) {
                    CountdownFormSheetView()
                }
            }
        }
        .accentColor(.primary)
    }
}

private extension CountdownView {
    
    @ViewBuilder
    func gridButton() -> some View {
        Button(action: {
            gridState = gridState == .grid ? .rows : .grid
            UserDefaults.standard.savedGridState = gridState
        }) {
            Image(systemName: gridState == .grid ? "list.bullet" : "square.grid.2x2")
                .foregroundColor(.accentColor)
        }
    }
    
    @ViewBuilder
    func addNewButton() -> some View {
        Button(action: {
            isShowingAddSheet = true
        }) {
            Image(systemName: "plus.circle")
                .font(.title2)
                .foregroundColor(.accentColor)
        }
    }

}
