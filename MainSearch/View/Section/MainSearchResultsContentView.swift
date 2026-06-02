//
//  MainSearchResultsContentView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/4.
//

import SwiftUI

struct MainSearchResultsContentView<FilterHeader: View>: View {

    let screenState: MainSearchScreenState
    let loadMoreState: MainSearchLoadMoreState
    @ViewBuilder let filterHeader: () -> FilterHeader
    let onRowAppear: (MainSearchResultRow) -> Void
    let onRetryLoadMore: () -> Void

    var body: some View {
        Group {
            switch screenState {
            case .emptyPrompt:
                VStack(spacing: 0) {
                    filterHeader()
                    ContentUnavailableView {
                        Label("開始搜尋", systemImage: "magnifyingglass")
                    } description: {
                        Text("選擇類型，輸入上方搜尋列關鍵字。")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            case .loading:
                VStack(spacing: 0) {
                    filterHeader()
                    MainSearchListSkeletonView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            case .error(let message):
                VStack(spacing: 0) {
                    filterHeader()
                    ContentUnavailableView {
                        Label("搜尋失敗", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(message)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            case .emptyResults(let query):
                VStack(spacing: 0) {
                    filterHeader()
                    ContentUnavailableView {
                        Label("找不到結果", systemImage: "magnifyingglass")
                    } description: {
                        Text("沒有符合「\(query)」的結果，請換個關鍵字試試。")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            case .content(let rows):
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
                    } header: {
                        filterHeader()
                            .textCase(nil)
                            .listRowInsets(EdgeInsets())
                    }
                }
                .overlay(alignment: .bottom) {
                    switch loadMoreState {
                    case .hidden, .available:
                        EmptyView()
                    case .loading:
                        ProgressView()
                            .padding(.bottom, 12)
                    case .error(let loadMoreErrorMessage):
                        VStack(spacing: 8) {
                            Text(loadMoreErrorMessage)
                                .font(.footnote)
                                .foregroundStyle(ThemeColor.textSecondary)
                                .multilineTextAlignment(.center)

                            Button("重試載入更多") {
                                onRetryLoadMore()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.systemBackground))
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}
