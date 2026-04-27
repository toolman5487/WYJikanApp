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
            switch viewModel.screenState {
            case .loading:
                CharacterListLoadingView()
            case .error(let message):
                ErrorMessageView(message: message, height: 180)
            case .empty:
                Text("目前沒有角色資料")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 48)
            case .content(let rows, let inlineError, let footer):
                LazyVGrid(columns: CharacterListGridMetrics.columns, spacing: 16) {
                    ForEach(rows) { row in
                        NavigationLink {
                            CharacterDetailView(malId: row.malId)
                        } label: {
                            CharacterPersonGridItemView(row: row)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let message = inlineError {
                    ErrorMessageView(message: message)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }

                switch footer {
                case .hidden:
                    EmptyView()
                case .loadMore:
                    CharacterLoadMoreButton(
                        title: "載入更多角色",
                        isLoading: false,
                        isVisible: true,
                        action: viewModel.loadMore
                    )
                case .loadingMore:
                    CharacterLoadMoreButton(
                        title: "載入更多角色",
                        isLoading: true,
                        isVisible: true,
                        action: viewModel.loadMore
                    )
                }
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
