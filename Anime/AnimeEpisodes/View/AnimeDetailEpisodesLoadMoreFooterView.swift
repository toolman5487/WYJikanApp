//
//  AnimeDetailEpisodesLoadMoreFooterView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/15.
//

import SwiftUI

struct AnimeDetailEpisodesLoadMoreFooterView: View {
    let state: AnimeDetailEpisodesListViewModel.LoadMoreState
    let onLoadMore: () async -> Void
    let onRetry: () async -> Void

    var body: some View {
        PaginationLoadMoreFooterView(
            state: state,
            availablePresentation: .prominentButton(title: "載入更多集數"),
            loadingMinHeight: 44,
            onAvailableTap: {
                Task(priority: .userInitiated) {
                    await onLoadMore()
                }
            },
            onRetry: {
                Task(priority: .userInitiated) {
                    await onRetry()
                }
            }
        )
    }
}
