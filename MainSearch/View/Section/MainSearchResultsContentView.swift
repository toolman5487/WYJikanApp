//
//  MainSearchResultsContentView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/4.
//

import SwiftUI

struct MainSearchResultsContentView: View {

    let screenState: MainSearchScreenState

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
                    .listRowSeparator(.visible)
                }
                .listStyle(.plain)
            }
        }
    }
}
