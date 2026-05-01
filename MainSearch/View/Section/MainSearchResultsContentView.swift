//
//  MainSearchResultsContentView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/4.
//

import SwiftUI

struct MainSearchResultsContentView: View {

    let screenState: MainSearchScreenState
    let isLoadingMore: Bool
    let loadMoreErrorMessage: String?
    let onRowAppear: (MainSearchResultRow) -> Void
    let onRetryLoadMore: () -> Void

    var body: some View {
        Group {
            switch screenState {
            case .emptyPrompt:
                ContentUnavailableView {
                    Label("開始搜尋", systemImage: "magnifyingglass")
                } description: {
                    Text("選擇類型，輸入上方搜尋列關鍵字。")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loading:
                MainSearchListSkeletonView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .error(let message):
                ContentUnavailableView {
                    Label("搜尋失敗", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .emptyResults(let query):
                ContentUnavailableView {
                    Label("找不到結果", systemImage: "magnifyingglass")
                } description: {
                    Text("沒有符合「\(query)」的結果，請換個關鍵字試試。")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .content(let rows):
                List(rows) { row in
                    NavigationLink(value: row) {
                        MainSearchResultRowView(row: row)
                    }
                    .onAppear {
                        onRowAppear(row)
                    }
                    .listRowSeparator(.visible)
                }
                .overlay(alignment: .bottom) {
                    if isLoadingMore {
                        ProgressView()
                            .padding(.bottom, 12)
                    } else if let loadMoreErrorMessage {
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
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
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
