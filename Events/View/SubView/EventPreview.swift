import SwiftUI

struct EventPreview: View {
    var event: Event
    var gridState: GridState
    var isIpad = UIDevice.current.userInterfaceIdiom == .pad

    var body: some View {
        
        var blockHeight: CGFloat {
            let baseHeight: CGFloat = gridState == .rows ? 100 : 140
            return isIpad ? baseHeight + 30 : baseHeight
        }

        let verticalPadding: CGFloat = gridState == .rows ? 10 : 4

        ZStack {
            VStack(alignment: .leading, spacing: 4) {
                
                titleView()
                    .padding(.top, 10)

                Spacer()
                
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading) {
                        eventEmoji()
                        nextDate()
                    }
                    
                    Spacer()
                    
                    daysLeftLabel()
                        .padding(.trailing)
                }
                .padding(.top, gridState == .rows ? -5 : 0) // Slight adjustment
                .padding(.leading, 5)
                .padding(.bottom, 10) // Add bottom padding to balance top
            }
            .frame(height: blockHeight)
            .padding(.vertical, verticalPadding)
            .background(
                backgroundView()
                .clipShape(RoundedRectangle(cornerRadius: 15))
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private extension EventPreview {
    
    @ViewBuilder
    func eventEmoji() -> some View {
        Text(event.emoji)
            .font(.footnote)
            .padding(.leading, 10)
            .padding(.bottom, event.isToday ? 3 : 0)
            .shadow(color: .black.opacity(0.3), radius: 4)
    }
    
    @ViewBuilder
    func titleView() -> some View {
        Text(event.name)
            .fontWeight(.semibold)
            .lineLimit(gridState == .grid ? 2 : 1)
            .fixedSize(horizontal: false, vertical: true)
            .minimumScaleFactor(0.9)
            .font(.system(size: isIpad ? 22 : 19))
            .padding(.trailing, 10)
            .foregroundColor(.white)
            .padding(.leading, isIpad ? 10 : 13)
            .multilineTextAlignment(.leading)
            .shadow(color: Color.black.opacity(0.4), radius: 6)
    }
    
    @ViewBuilder
    func nextDate() -> some View {
        if !event.isToday {
            Text(event.nextDate, style: .date)
                .font(.footnote)
                .foregroundStyle(event.color).brightness(0.7)
                .padding(.leading, 10)
        }
    }
    
    @ViewBuilder
    func daysLeftLabel() -> some View {
        let days = event.daysLeftUntilNextDate
        
        VStack(alignment: .trailing, spacing: 0) {
            if days > 0 {
                Text("\(days)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(event.color).brightness(0.7)
                    .shadow(color: .black.opacity(0.3), radius: 6)
                Text("\(days == 1 ? "Day" : "Days" )")
                    .font(.footnote)
                    .foregroundColor(event.color).brightness(0.7)
                    .fontWeight(.medium)


            } else if days < 0 {
                Text("\(abs(days))")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(event.color).brightness(0.7)
                    .shadow(color: .black.opacity(0.3), radius: 6)

                Text("\(days == 1 ? "Day ago" : "Days ago")")
                    .font(.footnote)
                    .foregroundColor(event.color).brightness(0.7)
                    .fontWeight(.medium)

            }
            else if days == 0 {
                Text("\(abs(days))")
                    .font(.largeTitle)
                    .opacity(0)
                Text("Today")
                    .foregroundColor(event.color).brightness(0.7)
                    .fontWeight(.semibold)
                    .shadow(color: .black.opacity(0.3), radius: 6)
                
            }
        }
    }
    
    @ViewBuilder
    func backgroundView() -> some View {
        ZStack {
            if let blurredPhoto = event.blurredPreviewImage, AppSettings.shared.showEventPreviewBackground {
                Image(uiImage: blurredPhoto)
                    .resizable()
                    .scaledToFill()
            } else {
                event.color
            }
        }
    }
}
