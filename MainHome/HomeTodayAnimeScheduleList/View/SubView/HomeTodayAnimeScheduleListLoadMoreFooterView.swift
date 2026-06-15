//
//  HomeTodayAnimeScheduleListLoadMoreFooterView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/5/6.
//

import SwiftUI

// MARK: - HomeTodayAnimeScheduleListLoadMoreFooterView

struct HomeTodayAnimeScheduleListLoadMoreFooterView: View {

    // MARK: - Properties

    let state: HomeTodayAnimeScheduleListViewModel.LoadMoreState
    var progress: CGFloat = 0
    let onLoadMore: () -> Void
    let onRetry: () -> Void

    // MARK: - Body

    var body: some View {
        PaginationLoadMoreFooterView(
            state: state,
            availablePresentation: .endBounceHint(
                title: "載入更多作品",
                subtitle: "繼續往下拉展開更多",
                progress: progress
            ),
            onAvailableTap: onLoadMore,
            onRetry: onRetry
        )
    }
}
