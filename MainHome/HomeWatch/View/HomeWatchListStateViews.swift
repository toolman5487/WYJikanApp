//
//  HomeWatchListStateViews.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/9.
//

import SwiftUI

struct HomeWatchListLoadingView: View {

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(0..<8, id: \.self) { index in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.systemGray5))
                        .frame(width: 82, height: 120)

                    VStack(alignment: .leading, spacing: 12) {
                        SkeletonBar(width: 184, height: 16, cornerRadius: 8)
                        SkeletonBar(width: 128, height: 16, cornerRadius: 8)
                        SkeletonBar(width: 208, height: 12, cornerRadius: 8)
                    }

                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
}

struct HomeWatchListLoadMoreFooterView: View {

    // MARK: - Properties

    let state: HomeWatchListViewModel.LoadMoreState
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
                title: "載入更多影音",
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
