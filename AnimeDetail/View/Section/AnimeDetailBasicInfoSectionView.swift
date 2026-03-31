//
//  AnimeDetailBasicInfoSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import SwiftUI

struct AnimeDetailBasicInfoSectionView: View {
    let viewModel: AnimeDetailViewModel
    let anime: AnimeDetailDTO

    var body: some View {
        AnimeDetailSectionCard("基本資訊") {
            VStack(spacing: 10) {
                AnimeDetailInfoRow(title: "集數", value: anime.episodes.map(String.init) ?? "-")
                AnimeDetailInfoRow(
                    title: viewModel.seasonInfoRowTitle(for: anime),
                    value: viewModel.seasonBlockPrimaryText(for: anime),
                    subtitle: viewModel.seasonBlockSubtitle(for: anime)
                )
                if let weekly = viewModel.weeklyBroadcastScheduleText(for: anime) {
                    AnimeDetailInfoRow(title: "播出時間", value: weekly)
                }
                AnimeDetailInfoRow(title: "片長", value: viewModel.durationDisplayText(for: anime))
            }
        }
    }
}

struct AnimeDetailBasicInfoSectionSkeletonView: View {
    var body: some View {
        SectionCardSkeleton(rowCount: 5)
    }
}
