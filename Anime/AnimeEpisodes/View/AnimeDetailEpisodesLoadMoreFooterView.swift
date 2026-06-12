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

    @ViewBuilder
    var body: some View {
        switch state {
        case .hidden:
            EmptyView()
        case .available:
            Button("載入更多集數", action: loadMore)
                .buttonStyle(.borderedProminent)
                .tint(ThemeColor.sakura)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .center)
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 44)
        case .error(let failure):
            VStack(alignment: .leading, spacing: 12) {
                Text(failure.message)
                    .font(.footnote)
                    .foregroundStyle(ThemeColor.textSecondary)

                Button("重試載入更多", action: retry)
                    .buttonStyle(.borderedProminent)
                    .tint(ThemeColor.sakura)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func loadMore() {
        Task {
            await onLoadMore()
        }
    }

    private func retry() {
        Task {
            await onRetry()
        }
    }
}
