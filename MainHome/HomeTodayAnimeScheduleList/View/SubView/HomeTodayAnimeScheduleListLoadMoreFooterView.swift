//
//  HomeTodayAnimeScheduleListLoadMoreFooterView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/5.
//

import SwiftUI

struct HomeTodayAnimeScheduleListLoadMoreFooterView: View {

    // MARK: - Properties

    let state: HomeTodayAnimeScheduleListViewModel.LoadMoreState
    let onLoadMore: () -> Void
    let onRetry: () -> Void

    // MARK: - Body

    @ViewBuilder
    var body: some View {
        switch state {
        case .hidden:
            EmptyView()

        case .available:
            Button("載入更多", action: onLoadMore)
                .buttonStyle(.borderedProminent)
                .tint(ThemeColor.sakura)
                .frame(maxWidth: .infinity, alignment: .center)

        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 44)

        case .error(let failure):
            VStack(alignment: .leading, spacing: 12) {
                ErrorMessageView(state: ErrorMessageView.State(failure: failure))

                Button("重試載入更多", action: onRetry)
                    .buttonStyle(.borderedProminent)
                    .tint(ThemeColor.sakura)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
