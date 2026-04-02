//
//  MangaDetailBasicInfoSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/1.
//

import SwiftUI

struct MangaDetailBasicInfoSectionView: View {
    let viewModel: MangaDetailViewModel
    let manga: MangaDetailDTO

    var body: some View {
        AnimeDetailSectionCard("基本資訊") {
            VStack(spacing: 10) {
                AnimeDetailInfoRow(title: "話數", value: viewModel.chaptersDisplayText(for: manga))
                AnimeDetailInfoRow(title: "卷數", value: viewModel.volumesDisplayText(for: manga))
                AnimeDetailInfoRow(title: "連載期間", value: viewModel.publishedPeriodDisplayText(for: manga))
                AnimeDetailInfoRow(title: "連載狀態", value: publishingLabel)
            }
        }
    }

    private var publishingLabel: String {
        if manga.publishing == true {
            return "連載中"
        }
        return viewModel.mangaStatusDisplayText(for: manga)
    }
}
