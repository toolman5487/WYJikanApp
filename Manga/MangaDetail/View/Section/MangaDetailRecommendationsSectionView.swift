//
//  MangaDetailRecommendationsSectionView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/11.
//

import SwiftUI

struct MangaDetailRecommendationsSectionView: View {

    // MARK: - Properties

    let viewModel: MangaDetailViewModel
    let mangaTitle: String
    @Binding var isShowingRecommendationList: Bool
    @State private var recommendationListBounceProgress: CGFloat = 0

    // MARK: - Body

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
                            MangaDetailView(malId: row.malId)
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

    // MARK: - Private Views

    private var recommendationListDestination: some View {
        MangaDetailRecommendationsListView(
            mangaTitle: mangaTitle,
            rows: viewModel.recommendationRows(for: .list)
        )
    }
}
