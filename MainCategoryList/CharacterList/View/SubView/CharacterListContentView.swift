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
                FeatureEmptyStateCardView(
                    emptyState: .emptyCollection(
                        title: "目前沒有角色資料",
                        message: "稍後再回來看看。"
                    ),
                    minHeight: 180
                )
                .padding(.vertical, 24)

            case .content(let rows, let inlineError, _):
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
                    LoadMoreErrorFooterView(failure: failure) {
                        viewModel.loadMore()
                    }
                }
            }
        }
        .padding(.top, 8)
    }
}
