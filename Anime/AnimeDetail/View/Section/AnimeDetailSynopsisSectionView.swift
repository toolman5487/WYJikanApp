//
//  AnimeDetailSynopsisSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import SwiftUI

struct AnimeDetailSynopsisSectionView: View {
    let viewModel: AnimeDetailViewModel
    let anime: AnimeDetailDTO
    
    var body: some View {
        AnimeDetailSectionCard(sectionTitle) {
            VStack(alignment: .leading, spacing: 16) {
                Text(viewModel.synopsisDisplayText(for: anime))
                    .font(.body)
                    .foregroundStyle(ThemeColor.textPrimary.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
                if let url = viewModel.malWorkPageURL(for: anime) {
                    MALWorkPageOpenButton(url: url)
                }
            }
        }
    }

    private var sectionTitle: String {
        "作品簡介"
    }
}
