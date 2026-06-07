//
//  MainNewsView.swift
//  WYJikanApp
//

import SwiftUI

struct MainNewsView: View {
    @Environment(\.openURL) private var openURL
    @StateObject private var viewModel: MainNewsViewModel
    @State private var reloadTask: Task<Void, Never>?

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
                    reloadButton
                }
            }
            .task {
                await viewModel.loadIfNeeded()
            }
            .onDisappear {
                reloadTask?.cancel()
                reloadTask = nil
            }
        }
    }

    private var reloadButton: some View {
        Button {
            startReload()
        } label: {
            Image(systemName: "arrow.trianglehead.counterclockwise")
                .font(.body.weight(.bold))
                .foregroundStyle(viewModel.isRefreshing ? ThemeColor.textSecondary : ThemeColor.sakura)
                .symbolEffect(.rotate, options: .repeating, isActive: viewModel.isRefreshing)
                .opacity(viewModel.isRefreshing ? 0.7 : 1)
                .frame(width: 44, height: 44)
        }
        .disabled(viewModel.isRefreshing)
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
                startReload()
            }
            .transition(.opacity)
        case .content(let content), .refreshing(let content):
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

    private func startReload() {
        reloadTask?.cancel()
        reloadTask = Task {
            await viewModel.reload()
        }
    }
}

#Preview {
    MainNewsView()
}
