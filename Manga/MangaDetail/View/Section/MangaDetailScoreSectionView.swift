//
//  MangaDetailScoreSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/1.
//

import SwiftUI

struct MangaDetailScoreSectionView: View {
    let viewModel: MangaDetailViewModel
    let manga: MangaDetailDTO

    var body: some View {
        AnimeDetailSectionCard("評分與人氣") {
            VStack(spacing: 10) {
                AnimeDetailInfoRow(title: "連載期間", value: viewModel.publishedPeriodDisplayText(for: manga))
                AnimeDetailInfoRow(
                    title: "分數",
                    value: viewModel.scoreDisplayText(for: manga)
                )
                AnimeDetailInfoRow(title: "評分人數", value: manga.scoredBy.map { viewModel.formatNumber($0) } ?? "-")
                AnimeDetailInfoRow(title: "排名", value: manga.rank.map { "#\($0)" } ?? "-")
                AnimeDetailInfoRow(title: "人氣", value: manga.popularity.map { "#\($0)" } ?? "-")
                AnimeDetailInfoRow(title: "收藏", value: manga.favorites.map { viewModel.formatNumber($0) } ?? "-")
            }
        }
    }
}
