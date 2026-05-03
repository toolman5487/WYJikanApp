//
//  MangaCategoryDetailGridSectionView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/2.
//

import SwiftUI

struct MangaCategoryDetailGridSectionView: View {
    let items: [MangaCategoryItemDTO]
    let loadMoreState: MangaCategoryDetailViewModel.LoadMoreState
    let onItemAppear: (MangaCategoryItemDTO) -> Void
    let onLoadMore: () -> Void
    let onRetryLoadMore: () -> Void

    private let gridColumns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: gridColumns, spacing: 18) {
                ForEach(items) { item in
                    NavigationLink {
                        MangaDetailView(malId: item.id)
                    } label: {
                        MangaCategoryDetailGridCardView(item: item)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        onItemAppear(item)
                    }
                }
            }

            MangaCategoryDetailLoadMoreFooterView(
                state: loadMoreState,
                onLoadMore: onLoadMore,
                onRetry: onRetryLoadMore
            )
        }
    }
}
