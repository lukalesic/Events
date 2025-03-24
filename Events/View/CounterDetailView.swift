//
//  CounterDetailView.swift
//  Events
//
//  Created by Luka Lešić on 23.03.25.
//

import SwiftUI

struct CounterDetailView: View {
    
    var countdown: Countdown
    
    var body: some View {
        ZStack {
            VStack {
                LinearGradient(
                    gradient: Gradient(colors: [countdown.color.opacity(0.6), Color.clear]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                
                Spacer()
            }
        }
    }
}

