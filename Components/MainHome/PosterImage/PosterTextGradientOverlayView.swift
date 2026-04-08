//
//  PosterTextGradientOverlayView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import SwiftUI

struct PosterTextGradientOverlayView: View {
    var body: some View {
        LinearGradient(
            colors: [
                .clear,
                Color.black.opacity(0.55)
            ],
            startPoint: .center,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }
}

#Preview {
    PosterTextGradientOverlayView()
}
