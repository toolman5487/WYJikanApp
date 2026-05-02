//
//  AnimeCategoryDetailGridSectionView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/2.
//

import SwiftUI

struct AnimeCategoryDetailGridSectionView: View {
    let items: [AnimeCategoryItemDTO]
    let loadMoreState: AnimeCategoryDetailViewModel.LoadMoreState
    let onItemAppear: (AnimeCategoryItemDTO) -> Void
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
                        AnimeDetailView(malId: item.id)
                    } label: {
                        AnimeCategoryDetailGridCardView(item: item)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        onItemAppear(item)
                    }
                }
            }

            AnimeCategoryDetailLoadMoreFooterView(
                state: loadMoreState,
                onLoadMore: onLoadMore,
                onRetry: onRetryLoadMore
            )
        }
    }
}
