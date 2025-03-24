//
//  CounterBlockView.swift
//  Events
//
//  Created by Luka Lešić on 23.03.25.
//

import SwiftUI

struct CounterBlockView: View {
    var countdown: Countdown
    
    var body: some View {
        NavigationStack {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .frame(minHeight: 130)
                    .foregroundColor(countdown.color)
                
                Text("\(countdown.daysLeft)")
                    .font(.largeTitle)
                    .foregroundColor(.white)
            }
            .tint(.orange)
        }
    }
}
