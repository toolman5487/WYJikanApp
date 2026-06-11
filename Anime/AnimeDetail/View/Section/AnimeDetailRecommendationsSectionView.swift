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
    @Binding var isShowingRecommendationList: Bool
    @State private var recommendationListBounceProgress: CGFloat = 0

    var body: some View {
        AnimeDetailLinkedSection(
            title: "你可能也喜歡",
            actionTitle: "更多推薦"
        ) {
            recommendationListDestination
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
                                    imageURL: viewModel.recommendationImageURL(recommendation),
                                    cardWidth: 160,
                                    cardHeight: 240,
                                    cornerRadius: 16,
                                    textMinHeight: 44
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if canShowRecommendationList {
                        EndBounceHintView(
                            axis: .horizontal,
                            title: "更多推薦",
                            subtitle: "繼續向右滑看完整清單",
                            progress: recommendationListBounceProgress,
                            width: 160,
                            height: 240,
                            cornerRadius: 16
                        )
                    }
                }
                .padding(.vertical, 4)
            }
            .onEndBounce(
                axis: .horizontal,
                isEnabled: canShowRecommendationList,
                progress: $recommendationListBounceProgress
            ) {
                isShowingRecommendationList = true
            }
        }
    }

    private var canShowRecommendationList: Bool {
        viewModel.allRecommendations.count > viewModel.previewRecommendations.count
    }

    private var recommendationListDestination: some View {
        AnimeDetailRecommendationsListView(
            animeTitle: animeTitle,
            recommendations: viewModel.allRecommendations,
            viewModel: viewModel
        )
    }
}

struct AnimeDetailRecommendationsListView: View {
    let animeTitle: String
    let recommendations: [AnimeRecommendationDTO]
    let viewModel: AnimeDetailViewModel

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
                            AnimeDetailView(malId: entry.malId)
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
        .navigationTitle("\(animeTitle) 推薦")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func recommendationPoster(_ recommendation: AnimeRecommendationDTO) -> some View {
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
