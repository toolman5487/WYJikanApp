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
            if viewModel.isLoading {
                PeopleListLoadingView()
            } else if let message = viewModel.errorMessage, viewModel.rows.isEmpty {
                ErrorMessageView(message: message, height: 180)
            } else if viewModel.rows.isEmpty {
                Text("目前沒有聲優資料")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 48)
            } else {
                LazyVGrid(columns: PeopleListGridMetrics.columns, spacing: 16) {
                    ForEach(viewModel.rows) { row in
                        NavigationLink {
                            PeopleDetailView(malId: row.malId)
                        } label: {
                            PeopleGridItemView(row: row)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let message = viewModel.errorMessage {
                    ErrorMessageView(message: message)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }

                PeopleLoadMoreButton(
                    title: "載入更多聲優",
                    isLoading: viewModel.isLoadingMore,
                    isVisible: viewModel.hasNextPage,
                    action: viewModel.loadMore
                )
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
