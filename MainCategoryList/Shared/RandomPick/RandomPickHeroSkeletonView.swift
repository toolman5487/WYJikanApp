//
//  RandomPickHeroSkeletonView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/9.
//

import SwiftUI

struct RandomPickHeroSkeletonView: View {

    // MARK: - Properties

    let height: CGFloat

    // MARK: - Body

    var body: some View {
        BannerSkeletonView()
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .frame(height: height)
    }
}

// MARK: - Preview

#Preview {
    RandomPickHeroSkeletonView(height: 320)
}
