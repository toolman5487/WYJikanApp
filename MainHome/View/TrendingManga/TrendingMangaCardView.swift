//
//  TrendingMangaCardView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import SwiftUI

struct TrendingMangaCardView: View {
    private static let cornerRadius: CGFloat = 16
    private static let rankPadding: CGFloat = 6

    let item: HomeTrendingMangaCardItem

    var body: some View {
        ZStack {
            TrendingMangaImageView(url: item.imageURL)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.06))

            LinearGradient(
                colors: [
                    .clear,
                    Color.black.opacity(0.75)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottomLeading) {
            if let rank = item.rank {
                Text("#\(rank)")
                    .font(.caption.weight(.bold))
                    .padding(8)
                    .foregroundStyle(ThemeColor.textPrimary)
                    .background(ThemeColor.sakuraGlassStrong)
                    .clipShape(Capsule())
                    .padding(Self.rankPadding)
            }
        }
        .compositingGroup()
        .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
    }
}

