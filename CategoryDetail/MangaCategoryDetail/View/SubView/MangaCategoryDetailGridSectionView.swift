//
//  MangaCategoryDetailGridSectionView.swift
//  WYJikanApp
//
//  Created by Codex on 2025/5/2.
//

import SwiftUI

struct MangaCategoryDetailGridSectionView: View {

    let items: [MangaCategoryItemDTO]
    let favoriteIDs: Set<Int>
    let loadMoreState: MangaCategoryDetailViewModel.LoadMoreState
    var loadMoreProgress: CGFloat = 0
    let onItemAppear: (MangaCategoryItemDTO) -> Void
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
    }
}
