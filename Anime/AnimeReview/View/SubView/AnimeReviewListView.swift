//
//  AnimeReviewListView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

import SwiftUI

struct AnimeReviewListView: View {
    
    @ObservedObject var viewModel: AnimeReviewViewModel
    @State private var loadMoreBounceProgress: CGFloat = 0
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(Array(viewModel.reviews.enumerated()), id: \.element.id) { index, entry in
                    if index > 0 {
                        Divider()
                    }
                    AnimeReviewRowView(viewModel: viewModel, entry: entry)
                }

                PaginationLoadMoreFooterView(
                    state: viewModel.loadMoreState,
                    availablePresentation: .endBounceHint(
                        title: "載入更多評論",
                        subtitle: "繼續往下拉展開更多",
                        progress: loadMoreBounceProgress
                    ),
                    onRetry: {
                        Task { await viewModel.loadMore() }
                    }
                )
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onEndBounce(
            axis: .vertical,
            isEnabled: canLoadMore,
            threshold: 16,
            revealDistance: 220,
            progress: $loadMoreBounceProgress
        ) {
            Task { await viewModel.loadMore() }
        }
    }

    private var canLoadMore: Bool {
        viewModel.loadMoreState == .available
    }
}
