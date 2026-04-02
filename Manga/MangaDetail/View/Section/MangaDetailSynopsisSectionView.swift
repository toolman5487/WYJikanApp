//
//  MangaDetailSynopsisSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/1.
//

import SwiftUI

struct MangaDetailSynopsisSectionView: View {
    let viewModel: MangaDetailViewModel
    let manga: MangaDetailDTO

    var body: some View {
        AnimeDetailSectionCard("作品簡介") {
            VStack(alignment: .leading, spacing: 16) {
                Text(viewModel.synopsisDisplayText(for: manga))
                    .font(.body)
                    .foregroundStyle(ThemeColor.textPrimary.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
                if let url = viewModel.malWorkPageURL(for: manga) {
                    MALWorkPageOpenButton(url: url)
                }
            }
        }
    }
}
