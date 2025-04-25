import SwiftUI

struct EventPreview: View {
    var event: Event
    var gridState: GridState

    var body: some View {
        let blockHeight: CGFloat = gridState == .rows ? 100 : 140
        let verticalPadding: CGFloat = gridState == .rows ? 10 : 0

        ZStack {
            VStack(alignment: .leading, spacing: 4) {

                titleView()
                
                Spacer()
                    .frame(maxHeight: 1)

                HStack(alignment: .bottom) {
                    nextDate()

                    Spacer()
                    
                    daysLeftLabel()
                    .padding(.trailing)
                }
                .padding(.top, gridState == .rows ? -15 : -5)
                .padding(.leading, 5)
            }
            .frame(height: blockHeight)
            .padding(.vertical, verticalPadding)
            .background(
                backgroundView()
                .clipShape(RoundedRectangle(cornerRadius: 12))
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private extension EventPreview {
    
    @ViewBuilder
    func titleView() -> some View {
        HStack(spacing: 0) {
            Text(event.emoji)
            Text(event.name)
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
    }
    
    @ViewBuilder
    func nextDate() -> some View {
        Text(event.nextDate, style: .date)
            .font(.footnote)
            .foregroundColor(.white.opacity(0.8))
            .padding(.leading, 10)
            .opacity(event.daysLeftUntilNextDate == 0 ? 0 : 1)
    }
    
    @ViewBuilder
    func daysLeftLabel() -> some View {
        let days = event.daysLeftUntilNextDate

        VStack(spacing: 1) {
            if days > 0 {
                Text("\(days)")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                Text("\(days == 1 ? "Day" : "Days" )")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.8))
            } else if days < 0 {
                Text("\(abs(days))")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                Text("\(days == 1 ? "Day ago" : "Days ago")")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.8))
            }
            else if days == 0 {
                Text("\(abs(days))")
                    .font(.largeTitle)
                    .opacity(0)
                Text("Today")
                    .foregroundColor(.white)
            }
        }
    }

    @ViewBuilder
    func backgroundView() -> some View {
        ZStack {
            if gridState == .rows {
                if let photo = event.previewImage {
                    Image(uiImage: photo)
                        .resizable()
                        .frame(width: 400, height: 150)
                        .blur(radius: 4)
                } else {
                    event.color
                }
            } else
            {
                if let photo = event.previewImage {
                    Image(uiImage: photo)
                        .resizable()
                        .frame(width: 200, height: 150)
                        .blur(radius: 4)
                    
                } else {
                    event.color
                    
                }
            }
            
//            if let photo = countdown.photo {
//                Image(uiImage: photo)
//                    .resizable()
//                    .drawingGroup(opaque: true)
//                    .scaledToFill()
//                    .blur(radius: 4)
//                    .overlay(Color.black.opacity(0.2))
//            } else {
        //TODO Performance issues!
//                countdown.color
            }
//                            .drawingGroup(opaque: true)

//        }
    }
}
