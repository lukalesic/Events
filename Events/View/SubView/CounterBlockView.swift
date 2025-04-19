import SwiftUI

struct CounterBlockView: View {
    var countdown: Countdown
    var gridState: GridState

    var body: some View {
        let blockHeight: CGFloat = gridState == .rows ? 100 : 140
        let verticalPadding: CGFloat = gridState == .rows ? 10 : 0

        ZStack {
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

                Spacer()
                    .frame(maxHeight: 1)

                // Days Left (Bottom Right)
                HStack(alignment: .bottom) {
                    Text(countdown.nextDate, style: .date)
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.leading, 10)

                    Spacer()
                    VStack(spacing: 1) {
                        Text("\(countdown.daysLeftUntilNextDate)")
                            .font(.largeTitle)
                            .foregroundColor(.white)

                        Text("Days")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.trailing)
                }
                .padding(.top, gridState == .rows ? -15 : -5)
                .padding(.leading, 5)
            }
            .frame(height: blockHeight)
            .padding(.vertical, verticalPadding)
            .background(
                ZStack {
                    if let photo = countdown.photo {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                            .blur(radius: 1.5)
                            .overlay(Color.black.opacity(0.2))
                    } else {
                        countdown.color
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
