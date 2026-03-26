//
//  TrendingAnimeCardView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import SwiftUI

struct TrendingAnimeCardView: View {
    private static let cornerRadius: CGFloat = 16
    
    let item: HomeTrendingAnimeCardItem
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            TrendingAnimeImageView(url: item.imageURL)
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
            .allowsHitTesting(false)
            
            if let rank = item.rank {
                Text("#\(rank)")
                    .font(.caption.weight(.bold))
                    .padding(8)
                    .foregroundStyle(ThemeColor.textPrimary)
                    .background(ThemeColor.sakuraGlassStrong)
                    .clipShape(Capsule())
                    .padding(4)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
    }
}

