//
//  AnimeCategoryDetailGridSectionView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/2.
//

import SwiftUI

struct AnimeCategoryDetailGridSectionView: View {

    let items: [AnimeCategoryItemDTO]
    let favoriteIDs: Set<Int>
    let loadMoreState: AnimeCategoryDetailViewModel.LoadMoreState
    var loadMoreProgress: CGFloat = 0
    let onItemAppear: (AnimeCategoryItemDTO) -> Void
    let onLoadMore: () -> Void
    let onRetryLoadMore: () -> Void

    var body: some View {
        PaginatedItemListSection(
            items: items,
            loadMoreState: loadMoreState,
            loadMoreProgress: loadMoreProgress,
            loadMoreAvailableTitle: "載入更多作品",
            loadMoreAvailableSubtitle: "繼續往下拉展開更多",
            onLoadMoreTap: onLoadMore,
            onRetryLoadMore: onRetryLoadMore
        ) { item in
            NavigationLink {
                AnimeDetailView(malId: item.id)
            } label: {
                AnimeCategoryDetailGridCardView(
                    item: item,
                    isFavorite: favoriteIDs.contains(item.id)
                )
            }
            .buttonStyle(.plain)
            .onAppear {
                onItemAppear(item)
            }
        }
    }
}
