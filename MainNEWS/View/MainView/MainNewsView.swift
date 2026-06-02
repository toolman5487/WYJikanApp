//
//  MainNewsView.swift
//  WYJikanApp
//

import SwiftUI

struct MainNewsView: View {
    @Environment(\.openURL) private var openURL
    @StateObject private var viewModel: MainNewsViewModel

    init(viewModel: MainNewsViewModel = MainNewsViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    MainNewsHeaderView(
                        content: viewModel.headerContent
                    )

                    MainNewsSourceFilterBarView(
                        filters: viewModel.filterItems,
                        selection: viewModel.selectedFilter,
                        onSelect: viewModel.selectFilter(_:)
                    )

                    stateContentView
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .navigationTitle("動漫新知")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemBackground))
            .refreshable {
                await viewModel.reload()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.reload() }
                    } label: {
                        Image(systemName: "arrow.trianglehead.counterclockwise")
                            .font(.body.weight(.bold))
                            .foregroundStyle(ThemeColor.sakura)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("重新載入動漫新知")
                }
            }
            .task {
                await viewModel.loadIfNeeded()
            }
        }
    }

    @ViewBuilder
    private var stateContentView: some View {
        switch viewModel.screenState {
        case .loading:
            MainNewsLoadingView()
                .transition(.opacity)
        case .empty:
            MainNewsEmptyStateView(filterTitle: viewModel.selectedFilter.title)
                .transition(.opacity)
        case .error(let message):
            MainNewsErrorStateView(message: message) {
                Task { await viewModel.reload() }
            }
            .transition(.opacity)
        case .content(let content):
            LazyVStack(spacing: 12) {
                ForEach(content.rows) { row in
                    MainNewsArticleRowView(row: row) {
                        openURL(row.linkURL)
                    }
                }
            }
            .transition(.opacity)
        }
    }
}

#Preview {
    MainNewsView()
}
