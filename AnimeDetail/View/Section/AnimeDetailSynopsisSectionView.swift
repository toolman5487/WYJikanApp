//
//  AnimeDetailSynopsisSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import SwiftUI

struct AnimeDetailSynopsisSectionView: View {
    let anime: AnimeDetailDTO
    
    var body: some View {
        AnimeDetailSectionCard("作品簡介") {
            Text(anime.synopsis ?? "-")
                .font(.body)
                .foregroundStyle(ThemeColor.textPrimary.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct AnimeDetailSynopsisSectionSkeletonView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(.systemGray5))
            .frame(maxWidth: .infinity)
            .frame(height: 120)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
