//
//  MangaDetailRecommendationsSectionView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/11.
//

import SwiftUI

struct MangaDetailRecommendationsSectionView: View {
    let viewModel: MangaDetailViewModel
    let mangaTitle: String
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
                                MangaDetailView(malId: entry.malId)
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
        MangaDetailRecommendationsListView(
            mangaTitle: mangaTitle,
            recommendations: viewModel.allRecommendations,
            viewModel: viewModel
        )
    }
}
