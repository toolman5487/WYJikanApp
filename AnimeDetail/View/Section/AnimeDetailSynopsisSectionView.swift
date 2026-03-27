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
