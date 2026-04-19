//
//  CharacterListContentView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/19.
//

import SwiftUI

struct CharacterListContentView: View {
    @ObservedObject var viewModel: CharacterListViewModel

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 14) {
            if viewModel.isLoading {
                CharacterListLoadingView()
            } else if let message = viewModel.errorMessage, viewModel.rows.isEmpty {
                ErrorMessageView(message: message, height: 180)
            } else if viewModel.rows.isEmpty {
                Text("目前沒有角色資料")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 48)
            } else {
                LazyVGrid(columns: CharacterListGridMetrics.columns, spacing: 16) {
                    ForEach(viewModel.rows) { row in
                        CharacterPersonGridItemView(row: row)
                    }
                }

                if let message = viewModel.errorMessage {
                    ErrorMessageView(message: message)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }

                CharacterLoadMoreButton(
                    title: "載入更多角色",
                    isLoading: viewModel.isLoadingMore,
                    isVisible: viewModel.hasNextPage,
                    action: viewModel.loadMore
                )
            }
        }
        .padding(.top, 8)
    }
}

enum CharacterListGridMetrics {
    static let columns = Array(
        repeating: GridItem(.flexible(), spacing: 12, alignment: .top),
        count: 3
    )
}
