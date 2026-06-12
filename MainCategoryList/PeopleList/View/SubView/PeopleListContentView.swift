//
//  PeopleListContentView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/19.
//

import SwiftUI

struct PeopleListContentView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: PeopleListViewModel

    // MARK: - Body

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            switch viewModel.screenState {
            case .loading:
                PeopleListLoadingView()

            case .error(let failure):
                ErrorMessageRetryCardView(
                    state: ErrorMessageView.State(failure: failure),
                    title: "聲優列表暫時載入失敗",
                    retryTitle: "重新載入"
                ) {
                    viewModel.reload()
                }

            case .empty:
                FeatureEmptyStateCardView(
                    emptyState: .emptyCollection(
                        title: "目前沒有聲優資料",
                        message: "稍後再回來看看。"
                    ),
                    minHeight: 180
                )
                .padding(.vertical, 24)

            case .content(let rows, let inlineError, let footer):
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(rows) { row in
                        NavigationLink {
                            PeopleDetailView(malId: row.malId)
                        } label: {
                            PeopleGridItemView(row: row)
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
