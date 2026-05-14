//
//  AnimeDetailRecommendationsSectionView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/14.
//

import Foundation
import SwiftUI

struct AnimeDetailRecommendationsSectionView: View {
    let viewModel: AnimeDetailViewModel
    let animeTitle: String

    var body: some View {
        AnimeDetailLinkedSection(
            title: "你可能也喜歡",
            actionTitle: "更多推薦"
        ) {
            AnimeDetailRecommendationsListView(
                animeTitle: animeTitle,
                recommendations: viewModel.allRecommendations,
                viewModel: viewModel
            )
        } content: {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(viewModel.previewRecommendations) { recommendation in
                        if let entry = recommendation.entry {
                            NavigationLink {
                                AnimeDetailView(malId: entry.malId)
                            } label: {
                                AnimeDetailRecommendationCardView(
                                    title: viewModel.recommendationTitle(recommendation),
                                    summary: viewModel.recommendationSummaryText(recommendation),
                                    imageURL: viewModel.recommendationImageURL(recommendation)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

private struct AnimeDetailRecommendationsListView: View {
    let animeTitle: String
    let recommendations: [AnimeRecommendationDTO]
    let viewModel: AnimeDetailViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 16, alignment: .top),
        GridItem(.flexible(), spacing: 16, alignment: .top)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 20) {
                ForEach(recommendations) { recommendation in
                    if let entry = recommendation.entry {
                        NavigationLink {
                            AnimeDetailView(malId: entry.malId)
                        } label: {
                            VStack(alignment: .leading, spacing: 12) {
                                recommendationPoster(recommendation)
                                    .aspectRatio(2.0 / 3.0, contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                                Text(viewModel.recommendationTitle(recommendation))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(ThemeColor.textPrimary)
                                    .lineLimit(2)

                                Text(viewModel.recommendationSummaryText(recommendation))
                                    .font(.caption)
                                    .foregroundStyle(ThemeColor.textSecondary)
                                    .lineLimit(3)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("\(animeTitle) 推薦")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func recommendationPoster(_ recommendation: AnimeRecommendationDTO) -> some View {
        if let imageURL = viewModel.recommendationImageURL(recommendation) {
            RemotePosterImageView(url: imageURL)
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray5))
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(ThemeColor.textTertiary)
                }
        }
    }
}
