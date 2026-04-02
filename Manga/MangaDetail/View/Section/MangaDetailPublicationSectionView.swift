//
//  MangaDetailPublicationSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/1.
//

import SwiftUI

struct MangaDetailPublicationSectionView: View {
    let viewModel: MangaDetailViewModel
    let manga: MangaDetailDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if viewModel.hasPublicationInfo(for: manga) {
                let authorsText = viewModel.joinedNames(from: manga.authors)
                let serializationsText = viewModel.joinedNames(from: manga.serializations)
                let genresText = viewModel.joinedNames(from: manga.genres)
                let demographicsText = viewModel.joinedNames(from: manga.demographics)
                AnimeDetailSectionCard("出版資訊") {
                    VStack(spacing: 10) {
                        AnimeDetailInfoRow(title: "作者", value: authorsText)
                        AnimeDetailInfoRow(title: "連載", value: serializationsText)
                        AnimeDetailInfoRow(title: "類型", value: genresText)
                        AnimeDetailInfoRow(title: "族群", value: demographicsText)
                    }
                }
            }
            if viewModel.hasThemes(for: manga) {
                VStack(alignment: .leading, spacing: 16) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(viewModel.themeDisplayItems(for: manga)) { theme in
                                Text(theme.name ?? "—")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(ThemeColor.textPrimary)
                                    .lineLimit(1)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .frame(minHeight: 44)
                                    .background(ThemeColor.sakura)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    if !viewModel.hasSynopsis(for: manga), let url = viewModel.malWorkPageURL(for: manga) {
                        MALWorkPageOpenButton(url: url)
                    }
                }
            }
            if !viewModel.hasSynopsis(for: manga), !viewModel.hasThemes(for: manga),
               let url = viewModel.malWorkPageURL(for: manga) {
                MALWorkPageOpenButton(url: url)
            }
        }
    }
}
