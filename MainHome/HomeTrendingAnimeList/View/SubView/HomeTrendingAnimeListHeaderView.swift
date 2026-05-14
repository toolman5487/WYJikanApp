//
//  HomeTrendingAnimeListHeaderView.swift
//  WYJikanApp
//
//  Created by Willy Hsu 2026/5/5.
//

import SwiftUI

struct HomeTrendingAnimeListHeaderView: View {
    let title: String
    let subtitle: String
    let loadedCountText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(ThemeColor.sakura)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(ThemeColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(loadedCountText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(ThemeColor.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemBackground).opacity(0.74))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(headerBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var headerBackground: some View {
        LinearGradient(
            colors: [
                ThemeColor.sakura.opacity(0.24),
                ThemeColor.sakura.opacity(0.10),
                Color(.secondarySystemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
