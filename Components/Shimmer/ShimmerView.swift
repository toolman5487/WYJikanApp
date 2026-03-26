//
//  ShimmerView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import SwiftUI

struct ShimmerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -0.3

    private let animation = Animation.linear(duration: 1.1)
        .repeatForever(autoreverses: false)

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let bandWidth = max(width * 0.28, 90)

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .white.opacity(0.16), location: 0.35),
                    .init(color: .white.opacity(0.32), location: 0.5),
                    .init(color: .white.opacity(0.16), location: 0.65),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: bandWidth)
            .rotationEffect(.degrees(18))
            .offset(x: phase * (width + bandWidth))
            .onAppear {
                guard !reduceMotion else { return }
                phase = -0.3
                withAnimation(animation) {
                    phase = 1.0
                }
            }
            .onChange(of: reduceMotion) {
                if reduceMotion {
                    phase = -0.3
                } else {
                    phase = -0.3
                    withAnimation(animation) {
                        phase = 1.0
                    }
                }
            }
        }
        .clipped()
        .allowsHitTesting(false)
    }
}

#Preview {
    ShimmerView()
}
