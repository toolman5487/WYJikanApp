//
//  MyListCollectionStatusBadgeView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/4/25.
//

import SwiftUI

struct MyListCollectionStatusBadgeView: View {

    // MARK: - Properties

    let isFavorite: Bool

    // MARK: - Body

    var body: some View {
        Image(systemName: isFavorite ? "heart.fill" : "heart")
            .font(.caption.weight(.bold))
            .foregroundStyle(ThemeColor.sakura)
            .padding(8)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(Color.white.opacity(0.14), lineWidth: 0.8)
            }
            .allowsHitTesting(false)
    }
}
