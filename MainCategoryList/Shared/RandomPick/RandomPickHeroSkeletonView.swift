//
//  RandomPickHeroSkeletonView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/9.
//

import SwiftUI

struct RandomPickHeroSkeletonView: View {

    // MARK: - Body

    var body: some View {
        BannerSkeletonView()
            .clipShape(
                RoundedRectangle(
                    cornerRadius: RandomPickHeroLayout.cardCornerRadius,
                    style: .continuous
                )
            )
            .frame(height: RandomPickHeroLayout.heroHeight)
    }
}

// MARK: - Preview

#Preview {
    RandomPickHeroSkeletonView()
}
