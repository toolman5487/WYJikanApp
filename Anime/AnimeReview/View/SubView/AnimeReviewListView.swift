//
//  AnimeReviewListView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

import SwiftUI

struct AnimeReviewListView: View {
    
    @ObservedObject var viewModel: AnimeReviewViewModel
    @State private var loadMoreBounceProgress: CGFloat = 0
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(Array(viewModel.reviews.enumerated()), id: \.element.id) { index, entry in
                    if index > 0 {
                        Divider()
                    }
                    AnimeReviewRowView(viewModel: viewModel, entry: entry)
                }

                loadMoreFooterView
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onEndBounce(
            axis: .vertical,
            isEnabled: canLoadMore,
            threshold: 16,
            revealDistance: 220,
            progress: $loadMoreBounceProgress
        ) {
            Task { await viewModel.loadMore() }
        }
    }

    @ViewBuilder
    private var loadMoreFooterView: some View {
        switch viewModel.loadMoreState {
        case .hidden:
            EmptyView()
        case .available:
            EndBounceHintView(
                axis: .vertical,
                title: "載入更多評論",
                subtitle: "繼續往下拉展開更多",
                progress: loadMoreBounceProgress
            )
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 116)
        case .error(let failure):
            VStack(alignment: .leading, spacing: 12) {
                ErrorMessageView(state: ErrorMessageView.State(failure: failure))

                Button {
                    Task { await viewModel.loadMore() }
                } label: {
                    Label("重試載入更多", systemImage: "arrow.trianglehead.counterclockwise")
                }
                .buttonStyle(.borderedProminent)
                .tint(ThemeColor.sakura)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var canLoadMore: Bool {
        switch viewModel.loadMoreState {
        case .available:
            return true
        case .hidden, .loading, .error:
            return false
        }
    }
}
