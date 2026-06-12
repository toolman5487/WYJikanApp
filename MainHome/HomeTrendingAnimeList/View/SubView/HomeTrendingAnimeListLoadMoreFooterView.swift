//
//  HomeTrendingAnimeListLoadMoreFooterView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/5/5.
//

import SwiftUI

struct HomeTrendingAnimeListLoadMoreFooterView: View {

    // MARK: - Properties

    let state: HomeTrendingAnimeListViewModel.LoadMoreState
    var progress: CGFloat = 0
    let onLoadMore: () -> Void
    let onRetry: () -> Void

    // MARK: - Body

    @ViewBuilder
    var body: some View {
        switch state {
        case .hidden:
            EmptyView()

        case .available:
            EndBounceHintView(
                axis: .vertical,
                title: "載入更多作品",
                subtitle: "繼續往下拉展開更多",
                progress: progress
            )

        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 116)

        case .error(let failure):
            LoadMoreErrorFooterView(failure: failure, onRetry: onRetry)
        }
    }
}
