//
//  AnimeCategoryDetailLoadMoreFooterView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/2.
//

import SwiftUI

struct AnimeCategoryDetailLoadMoreFooterView: View {

    let state: AnimeCategoryDetailViewModel.LoadMoreState
    var progress: CGFloat = 0
    let onLoadMore: () -> Void
    let onRetry: () -> Void

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
