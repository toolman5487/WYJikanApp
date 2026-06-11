//
//  MangaDetailPicturesSectionView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/11.
//

import SwiftUI

struct MangaDetailPicturesSectionView: View {
    let viewModel: MangaDetailViewModel
    let onTapImage: (Int) -> Void

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    var body: some View {
        AnimeDetailSectionCard("圖片") {
            LazyVGrid(columns: gridColumns, alignment: .center, spacing: 12) {
                ForEach(Array(viewModel.pictureItems.enumerated()), id: \.element.id) { index, item in
                    DetailPictureGridItemView(url: item.url) {
                        onTapImage(index)
                    }
                }
            }
        }
    }
}
