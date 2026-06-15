//
//  PosterTextGradientOverlayView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import SwiftUI

// MARK: - PosterTextGradientOverlayView

struct PosterTextGradientOverlayView: View {

    // MARK: - Body

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

// MARK: - Preview

#Preview {
    PosterTextGradientOverlayView()
}
