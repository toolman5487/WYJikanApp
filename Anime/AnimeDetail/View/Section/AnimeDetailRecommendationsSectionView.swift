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
                    ForEach(viewModel.recommendationRows(for: .preview)) { row in
                        NavigationLink {
                            AnimeDetailView(malId: row.malId)
                        } label: {
                            AnimeDetailRecommendationCardView(row: row)
                        }
                        .buttonStyle(.plain)
                    }

                    if viewModel.canShowFullRecommendationList {
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
                isEnabled: viewModel.canShowFullRecommendationList,
                progress: $recommendationListBounceProgress
            ) {
                isShowingRecommendationList = true
            }
        }
    }

    private var recommendationListDestination: some View {
        AnimeDetailRecommendationsListView(
            animeTitle: animeTitle,
            rows: viewModel.recommendationRows(for: .list)
        )
    }
}

struct AnimeDetailRecommendationsListView: View {
    let animeTitle: String
    let rows: [DetailRecommendationRow]

    var body: some View {
        AnimeDetailRecommendationsListLayout {
            ForEach(rows) { row in
                NavigationLink {
                    AnimeDetailView(malId: row.malId)
                } label: {
                    AnimeDetailRecommendationCardView(row: row)
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("\(animeTitle) 推薦")
        .navigationBarTitleDisplayMode(.inline)
    }
}
