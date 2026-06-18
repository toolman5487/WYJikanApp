//
//  MainSearchResultsContentView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/4.
//

import SwiftUI

struct MainSearchResultsContentView<FilterHeader: View>: View {

    // MARK: - Properties

    let screenState: MainSearchScreenState
    let loadMoreState: MainSearchLoadMoreState
    let loadMoreProgress: CGFloat
    let searchHistory: [MainSearchHistoryItem]
    @ViewBuilder let filterHeader: () -> FilterHeader
    let onRowAppear: (MainSearchResultRow) -> Void
    let onLoadMore: () -> Void
    let onRetryLoadMore: () -> Void
    let onSelectHistory: (MainSearchHistoryItem) -> Void
    let onRemoveHistory: (MainSearchHistoryItem) -> Void
    let onClearHistory: () -> Void

    // MARK: - Body

    var body: some View {
        Group {
            switch screenState {
            case .emptyPrompt:
                emptyPromptView
            case .loading:
                loadingView
            case .error(let failure):
                errorView(failure)
            case .emptyResults(let query):
                emptyResultsView(query: query)
            case .content(let rows):
                contentView(rows: rows)
            }
        }
    }

    // MARK: - Private Views

    private var emptyPromptView: some View {
        VStack(spacing: 0) {
            filterHeader()
            if searchHistory.isEmpty {
                FeatureEmptyStateCardView(
                    emptyState: .noSearchResults(
                        title: "開始搜尋",
                        message: "選擇類型，輸入上方搜尋列關鍵字。"
                    ),
                    minHeight: 200
                )
            } else {
                ScrollView {
                    MainSearchHistorySectionView(
                        items: searchHistory,
                        onSelect: onSelectHistory,
                        onRemove: onRemoveHistory,
                        onClear: onClearHistory
                    )
                    .padding(.top, 16)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var loadingView: some View {
        VStack(spacing: 0) {
            filterHeader()
            MainSearchListSkeletonView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func errorView(_ failure: FeatureLoadFailure) -> some View {
        VStack(spacing: 0) {
            filterHeader()
            ErrorMessageView(
                state: ErrorMessageView.State(failure: failure),
                height: 200
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func emptyResultsView(query: String) -> some View {
        VStack(spacing: 0) {
            filterHeader()
            FeatureEmptyStateCardView(
                emptyState: .noSearchResults(
                    title: "找不到結果",
                    message: "沒有符合「\(query)」的結果，請換個關鍵字試試。"
                ),
                minHeight: 200
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func contentView(rows: [MainSearchResultRow]) -> some View {
        List {
            Section {
                ForEach(rows) { row in
                    NavigationLink(value: row) {
                        MainSearchResultRowView(row: row)
                    }
                    .onAppear {
                        onRowAppear(row)
                    }
                    .listRowSeparator(.visible)
                }

                loadMoreFooterView
            } header: {
                filterHeader()
                    .textCase(nil)
                    .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(.plain)
    }

    @ViewBuilder
    private var loadMoreFooterView: some View {
        PaginationLoadMoreFooterView(
            state: loadMoreState,
            availablePresentation: .endBounceHint(
                title: "載入更多結果",
                subtitle: "繼續往下拉展開更多",
                progress: loadMoreProgress
            ),
            onAvailableTap: onLoadMore,
            onRetry: onRetryLoadMore
        )
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 16, trailing: 16))
    }
}
