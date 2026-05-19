//
//  File.swift
//  Events
//
//  Created by Luka Lešić on 19.05.26.
//

import SwiftUI

struct CloseButton: View {
    
    var action: () -> Void
    
    var body: some View {
        if #available(iOS 26.0, *) {
            Button(role: .close) {
                action()
            }
        } else {
            Button("Done") {
                action()
            }
            .fontWeight(.semibold)
        }
    }
}


