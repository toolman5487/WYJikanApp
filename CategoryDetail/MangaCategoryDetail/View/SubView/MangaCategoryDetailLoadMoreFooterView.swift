//
//  MangaCategoryDetailLoadMoreFooterView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/2.
//

import SwiftUI

struct MangaCategoryDetailLoadMoreFooterView: View {

    // MARK: - Properties

    let state: MangaCategoryDetailViewModel.LoadMoreState
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

        case let .error(message):
            VStack(alignment: .leading, spacing: 12) {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(ThemeColor.textSecondary)

                Button {
                    onRetry()
                } label: {
                    Label("重試載入更多", systemImage: "arrow.trianglehead.counterclockwise")
                }
                .buttonStyle(.borderedProminent)
                .tint(ThemeColor.sakura)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
