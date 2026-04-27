//
//  PeopleListContentView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/19.
//

import SwiftUI

struct PeopleListContentView: View {
    @ObservedObject var viewModel: PeopleListViewModel

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 14) {
            switch viewModel.viewState {
            case .loading:
                PeopleListLoadingView()
            case .error(let message):
                ErrorMessageView(message: message, height: 180)
            case .empty:
                Text("目前沒有聲優資料")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 48)
            case .content(let rows, let inlineError, let footer):
                LazyVGrid(columns: PeopleListGridMetrics.columns, spacing: 16) {
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
                    ErrorMessageView(message: message)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }

                switch footer {
                case .hidden:
                    EmptyView()
                case .loadMore:
                    PeopleLoadMoreButton(
                        title: "載入更多聲優",
                        isLoading: false,
                        isVisible: true,
                        action: viewModel.loadMore
                    )
                case .loadingMore:
                    PeopleLoadMoreButton(
                        title: "載入更多聲優",
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

enum PeopleListGridMetrics {
    static let columns = Array(
        repeating: GridItem(.flexible(), spacing: 12, alignment: .top),
        count: 3
    )
}
