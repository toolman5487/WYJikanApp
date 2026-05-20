//
//  MangaCategoryDetailGridSectionView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/2.
//

import SwiftUI

struct MangaCategoryDetailGridSectionView: View {

    // MARK: - Properties

    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    let items: [MangaCategoryItemDTO]
    let loadMoreState: MangaCategoryDetailViewModel.LoadMoreState
    let onItemAppear: (MangaCategoryItemDTO) -> Void
    let onLoadMore: () -> Void
    let onRetryLoadMore: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: gridColumns, spacing: 20) {
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
