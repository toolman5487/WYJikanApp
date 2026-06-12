//
//  CharacterListContentView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/19.
//

import SwiftUI

struct CharacterListContentView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: CharacterListViewModel

    // MARK: - Body

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            switch viewModel.screenState {
            case .loading:
                CharacterListLoadingView()

            case .error(let failure):
                ErrorMessageRetryCardView(
                    state: ErrorMessageView.State(failure: failure),
                    title: "角色列表暫時載入失敗",
                    retryTitle: "重新載入"
                ) {
                    viewModel.reload()
                }

            case .empty:
                ErrorMessageView(
                    state: .emptyCollection("目前沒有角色資料"),
                    height: 180
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)

            case .content(let rows, let inlineError, let footer):
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(rows) { row in
                        NavigationLink {
                            CharacterDetailView(malId: row.malId)
                        } label: {
                            CharacterPersonGridItemView(row: row)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let failure = inlineError {
                    ErrorMessageView(state: ErrorMessageView.State(failure: failure))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }

                switch footer {
                case .hidden:
                    EmptyView()

                case .loadMore, .loadingMore:
                    EmptyView()
                }
            }
        }
        .padding(.top, 8)
    }
}
