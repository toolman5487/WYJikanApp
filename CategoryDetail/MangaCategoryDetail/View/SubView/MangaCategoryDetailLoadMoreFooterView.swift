//
//  MangaCategoryDetailLoadMoreFooterView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/2.
//

import SwiftUI

struct MangaCategoryDetailLoadMoreFooterView: View {
    let state: MangaCategoryDetailViewModel.LoadMoreState
    let onLoadMore: () -> Void
    let onRetry: () -> Void

    @ViewBuilder
    var body: some View {
        switch state {
        case .hidden:
            EmptyView()
        case .available:
            Button("載入更多作品") {
                onLoadMore()
            }
            .buttonStyle(.borderedProminent)
            .tint(ThemeColor.sakura)
            .frame(maxWidth: .infinity, alignment: .center)
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 44)
        case let .error(message):
            VStack(alignment: .leading, spacing: 10) {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(ThemeColor.textSecondary)

                Button("重試載入更多") {
                    onRetry()
                }
                .buttonStyle(.borderedProminent)
                .tint(ThemeColor.sakura)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
