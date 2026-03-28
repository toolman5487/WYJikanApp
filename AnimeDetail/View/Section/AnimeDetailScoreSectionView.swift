//
//  AnimeDetailScoreSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import SwiftUI

struct AnimeDetailScoreSectionView: View {
    let anime: AnimeDetailDTO
    
    var body: some View {
        AnimeDetailSectionCard("評分與人氣") {
            VStack(spacing: 10) {
                AnimeDetailInfoRow(
                    title: "分數",
                    value: anime.score.map { String(format: "%.2f", $0) + " / 10.0" } ?? " ⭐️"
                )
                AnimeDetailInfoRow(title: "評分人數", value: anime.scoredBy.map(anime.formatNumber(_:)) ?? "-")
                AnimeDetailInfoRow(title: "排名", value: anime.rank.map { "#\($0)" } ?? "-")
                AnimeDetailInfoRow(title: "人氣", value: anime.popularity.map { "#\($0)" } ?? "-")
                AnimeDetailInfoRow(title: "收藏", value: anime.favorites.map(anime.formatNumber(_:)) ?? "-")
            }
        }
    }
}

struct AnimeDetailScoreSectionSkeletonView: View {
    var body: some View {
        SectionCardSkeleton(titleWidth: 110, rowCount: 5)
    }
}
