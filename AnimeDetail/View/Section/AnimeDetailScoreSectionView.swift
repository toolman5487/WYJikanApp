//
//  AnimeDetailScoreSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import SwiftUI

struct AnimeDetailScoreSectionView: View {
    let viewModel: AnimeDetailViewModel
    let anime: AnimeDetailDTO

    var body: some View {
        NavigationLink {
            AnimeReviewView(malId: anime.malId, animeTitle: viewModel.displayTitle(for: anime))
        } label: {
            AnimeDetailSectionCard("評分與人氣") {
                VStack(spacing: 10) {
                    AnimeDetailInfoRow(
                        title: "分數",
                        value: viewModel.scoreDisplayText(for: anime)
                    )
                    AnimeDetailInfoRow(title: "評分人數", value: anime.scoredBy.map { viewModel.formatNumber($0) } ?? "-")
                    AnimeDetailInfoRow(title: "排名", value: anime.rank.map { "#\($0)" } ?? "-")
                    AnimeDetailInfoRow(title: "人氣", value: anime.popularity.map { "#\($0)" } ?? "-")
                    AnimeDetailInfoRow(title: "收藏", value: anime.favorites.map { viewModel.formatNumber($0) } ?? "-")
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct AnimeDetailScoreSectionSkeletonView: View {
    var body: some View {
        SectionCardSkeleton(rowCount: 5)
    }
}
