import SwiftUI

struct CounterBlockView: View {
    var countdown: Countdown
    var gridState: GridState
    
    var body: some View {
        NavigationStack {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .foregroundColor(countdown.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Name & Emoji (Top Left)
                    HStack(spacing: 0) {
                        Text(countdown.emoji)
                        Text(countdown.name)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .padding(.leading, 3)
                    }
                    .font(.system(size: 20))
                    .frame(height: gridState == .rows ? 40 : 50)
                    .padding(.trailing, 10)
                    .foregroundColor(.white)
                    .padding(.leading, 10)
                    .padding(.top, -7)
                    .multilineTextAlignment(.leading)

                    // Date Below Name
//                    Text(countdown.date, style: .date) // Displays the date
//                        .font(.footnote)
//                        .foregroundColor(.white.opacity(0.8))
//                        .padding(.leading, 10)

                    Spacer()
                        .frame(maxHeight: 1)

                    // Days Left (Bottom Right)
                    HStack(alignment: .bottom) {
                        
                        Text(countdown.date, style: .date) // Displays the date
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.leading, 10)

                        Spacer()
                        VStack(spacing: 1) {
                            Text("\(countdown.daysLeft)")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                            
                            Text("Days") // TODO: Make an option
                                .font(.footnote)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding([.trailing])
                    }
                    .padding(.top, gridState == .rows ? -15 : -5)
                    .padding(.leading, 5)
                }
                .frame(height: gridState == .rows ? 100 : 140)
                .padding(.vertical, gridState == .rows ? 10 : 0)
            }
        }
    }
}
