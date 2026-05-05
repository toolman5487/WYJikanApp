//
//  HomeTrendingAnimeListRankedSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu 2026/5/5.
//

import SwiftUI

struct HomeTrendingAnimeListRankedSectionView: View {
    let title: String
    let countText: String
    let items: [HomeTrendingAnimeListItem]
    let loadMoreState: HomeTrendingAnimeListViewModel.LoadMoreState
    let onItemAppear: (HomeTrendingAnimeListItem) -> Void
    let onTapItem: (HomeTrendingAnimeListItem) -> Void
    let onLoadMore: () -> Void
    let onRetryLoadMore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(ThemeColor.textPrimary)

                Text(countText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ThemeColor.textSecondary)

                Spacer()
            }

            LazyVStack(spacing: 14) {
                ForEach(items) { item in
                    HomeTrendingAnimeListRowView(item: item) {
                        onTapItem(item)
                    }
                    .onAppear {
                        onItemAppear(item)
                    }
                }

                HomeTrendingAnimeListLoadMoreFooterView(
                    state: loadMoreState,
                    onLoadMore: onLoadMore,
                    onRetry: onRetryLoadMore
                )
            }
        }
    }
}
