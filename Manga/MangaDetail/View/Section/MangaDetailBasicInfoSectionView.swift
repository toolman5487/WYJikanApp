//
//  MangaDetailBasicInfoSectionView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/11.
//

import SwiftUI

struct MangaDetailBasicInfoSectionView: View {
    let viewModel: MangaDetailViewModel
    let manga: MangaDetailDTO

    var body: some View {
        AnimeDetailSectionCard("基本資訊") {
            VStack(spacing: 12) {
                AnimeDetailInfoRow(
                    title: "連載期間",
                    value: viewModel.publishedPeriodDisplayText(for: manga)
                )
                AnimeDetailInfoRow(title: "卷數", value: viewModel.volumesDisplayText(for: manga))
                AnimeDetailInfoRow(title: "話數", value: viewModel.chaptersDisplayText(for: manga))
                AnimeDetailInfoRow(title: "狀態", value: viewModel.mangaStatusDisplayText(for: manga))
            }
        }
    }
}
