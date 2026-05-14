//
//  HomeTrendingAnimeListLoadMoreFooterView.swift
//  WYJikanApp
//
//  Created by Willy Hsu 2026/5/5.
//

import SwiftUI

struct HomeTrendingAnimeListLoadMoreFooterView: View {
    let state: HomeTrendingAnimeListViewModel.LoadMoreState
    let onLoadMore: () -> Void
    let onRetry: () -> Void

    @ViewBuilder
    var body: some View {
        switch state {
        case .hidden:
            EmptyView()
        case .available:
            Button("載入更多作品", action: onLoadMore)
                .buttonStyle(.borderedProminent)
                .tint(ThemeColor.sakura)
                .frame(maxWidth: .infinity, alignment: .center)
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 44)
        case .error(let message):
            VStack(alignment: .leading, spacing: 12) {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(ThemeColor.textSecondary)

                Button("重試載入更多", action: onRetry)
                    .buttonStyle(.borderedProminent)
                    .tint(ThemeColor.sakura)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
