//
//  MangaCategoryDetailGridSectionView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/2.
//

import SwiftUI

struct MangaCategoryDetailGridSectionView: View {

    // MARK: - Properties

    let items: [MangaCategoryItemDTO]
    let favoriteIDs: Set<Int>
    let loadMoreState: MangaCategoryDetailViewModel.LoadMoreState
    var loadMoreProgress: CGFloat = 0
    let onItemAppear: (MangaCategoryItemDTO) -> Void
    let onLoadMore: () -> Void
    let onRetryLoadMore: () -> Void

    // MARK: - Body

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            ForEach(items) { item in
                NavigationLink {
                    MangaDetailView(malId: item.id)
                } label: {
                    MangaCategoryDetailGridCardView(
                        item: item,
                        isFavorite: favoriteIDs.contains(item.id)
                    )
                }
                .buttonStyle(.plain)
                .onAppear {
                    onItemAppear(item)
                }
            }

            MangaCategoryDetailLoadMoreFooterView(
                state: loadMoreState,
                progress: loadMoreProgress,
                onLoadMore: onLoadMore,
                onRetry: onRetryLoadMore
            )
        }
    }
}
