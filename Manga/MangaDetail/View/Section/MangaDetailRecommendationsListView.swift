//
//  MangaDetailRecommendationsListView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/11.
//

import SwiftUI

struct MangaDetailRecommendationsListView: View {
    let mangaTitle: String
    let recommendations: [MangaRecommendationDTO]
    let viewModel: MangaDetailViewModel

    private let columns = [
        GridItem(
            .adaptive(
                minimum: 160,
                maximum: 160
            ),
            spacing: 16,
            alignment: .top
        )
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 20) {
                ForEach(recommendations) { recommendation in
                    if let entry = recommendation.entry {
                        NavigationLink {
                            MangaDetailView(malId: entry.malId)
                        } label: {
                            VStack(alignment: .leading, spacing: 12) {
                                recommendationPoster(recommendation)
                                    .frame(width: 160, height: 240)
                                    .clipShape(
                                        RoundedRectangle(
                                            cornerRadius: 16,
                                            style: .continuous
                                        )
                                    )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(viewModel.recommendationTitle(recommendation))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(ThemeColor.textPrimary)
                                        .lineLimit(1)

                                    Text(viewModel.recommendationSummaryText(recommendation))
                                        .font(.caption)
                                        .foregroundStyle(ThemeColor.textSecondary)
                                        .lineLimit(3)
                                }
                                .frame(
                                    minWidth: 160,
                                    maxWidth: 160,
                                    minHeight: 72,
                                    alignment: .topLeading
                                )
                            }
                            .frame(width: 160, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("\(mangaTitle) 推薦")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func recommendationPoster(_ recommendation: MangaRecommendationDTO) -> some View {
        if let imageURL = viewModel.recommendationImageURL(recommendation) {
            RemotePosterImageView(url: imageURL)
        } else {
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
                .fill(Color(.systemGray5))
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(ThemeColor.textTertiary)
                }
        }
    }
}
