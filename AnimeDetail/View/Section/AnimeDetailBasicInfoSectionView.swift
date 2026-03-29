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
                AnimeDetailInfoRow(title: "連載", value: viewModel.airingDisplayText(for: anime))
                AnimeDetailInfoRow(title: "集數", value: anime.episodes.map(String.init) ?? "-")
                AnimeDetailInfoRow(title: "播出季度", value: viewModel.seasonText(for: anime))
                AnimeDetailInfoRow(title: "播出時間", value: viewModel.broadcastDisplayText(for: anime))
                AnimeDetailInfoRow(title: "片長", value: anime.duration ?? "-")
            }
        }
    }
}

struct AnimeDetailBasicInfoSectionSkeletonView: View {
    var body: some View {
        SectionCardSkeleton(titleWidth: 88, rowCount: 5)
    }
}
