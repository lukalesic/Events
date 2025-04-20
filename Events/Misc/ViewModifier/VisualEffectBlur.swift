//
//  Teest.swift
//  Events
//
//  Created by Luka Lešić on 20.04.25.
//

import Foundation
import SwiftUI
import UIKit

struct VisualEffectBlur: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemUltraThinMaterial

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

