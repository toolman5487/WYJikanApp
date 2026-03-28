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
        VStack(alignment: .leading, spacing: 12) {
            SkeletonBar(width: 100, height: 22, cornerRadius: 6)

            VStack(alignment: .leading, spacing: 8) {
                SkeletonBar(width: nil, height: 14, cornerRadius: 4)
                SkeletonBar(width: nil, height: 14, cornerRadius: 4)
                SkeletonBar(width: nil, height: 14, cornerRadius: 4)
                SkeletonBar(width: 240, height: 14, cornerRadius: 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
