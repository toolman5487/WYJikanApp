//
//  AnimeDetailStaffSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import SwiftUI

struct AnimeDetailStaffSectionView: View {
    let viewModel: AnimeDetailViewModel
    let anime: AnimeDetailDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if viewModel.hasStaffInfo(for: anime) {
                let genreText = viewModel.joinedNames(from: anime.genres)
                AnimeDetailSectionCard("製作資訊") {
                    VStack(spacing: 12) {
                        AnimeDetailProducerInfoRow(
                            title: "工作室",
                            producers: anime.studios ?? []
                        )
                        AnimeDetailProducerInfoRow(
                            title: "製作",
                            producers: anime.producers ?? []
                        )
                        AnimeDetailInfoRow(title: "類型", value: genreText)
                    }
                }
            }
            if viewModel.hasThemes(for: anime) {
                VStack(alignment: .leading, spacing: 16) {
                    CapsuleTagScrollView(
                        tags: viewModel.themeDisplayItems(for: anime),
                        title: { $0.name ?? "—" }
                    )
                    if !viewModel.hasSynopsis(for: anime), let url = viewModel.malWorkPageURL(for: anime) {
                        MALWorkPageOpenButton(url: url)
                    }
                }
            }
        }
    }
}

private struct AnimeDetailProducerInfoRow: View {
    let title: String
    let producers: [AnimeRelatedEntityDTO]

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ThemeColor.textSecondary)
                .frame(width: 72, alignment: .leading)

            if displayItems.isEmpty {
                Text("—")
                    .font(.subheadline)
                    .foregroundStyle(ThemeColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(displayItems) { producer in
                            NavigationLink {
                                ProducerDetailView(malId: producer.malId)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "building.2")
                                        .font(.caption.weight(.semibold))
                                    Text(
                                        DisplayTextFormatting.nonEmpty(producer.name)
                                            ?? "未命名公司"
                                    )
                                    .lineLimit(1)
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(ThemeColor.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(ThemeColor.sakura.opacity(0.18))
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: 8,
                                        style: .continuous
                                    )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var displayItems: [AnimeRelatedEntityDTO] {
        producers.filter {
            DisplayTextFormatting.nonEmpty($0.name) != nil
        }
    }
}
