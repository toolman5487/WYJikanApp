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
                ErrorMessageView(state: .network(failure.message), height: 180)

            case .empty:
                Text("目前沒有聲優資料")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 48)

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

                if let message = inlineError {
                    ErrorMessageView(state: .network(message))
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
