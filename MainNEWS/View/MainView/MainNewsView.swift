//
//  MainNewsView.swift
//  WYJikanApp
//

import SwiftUI

struct MainNewsView: View {

    // MARK: - Properties

    @StateObject private var viewModel: MainNewsViewModel
    @State private var reloadTask: Task<Void, Never>?
    @State private var selectedArticle: MainNewsRow?

    // MARK: - Lifecycle

    init(dependencies: AppDependencies) {
        _viewModel = StateObject(wrappedValue: dependencies.makeMainNewsViewModel())
    }

    // MARK: - Body

    var body: some View {
        newsNavigationStack
    }

    // MARK: - Private Views

    private var newsNavigationStack: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    MainNewsHeaderView(content: viewModel.headerContent)

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
                .frame(maxWidth: .infinity, alignment: .leading)
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
            .navigationDestination(item: $selectedArticle) { row in
                BaseWebView(page: .newsArticle(sourceName: row.sourceName, url: row.linkURL))
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
            FeatureEmptyStateCardView(
                emptyState: .emptyCollection(
                    title: "目前沒有新聞",
                    message: "\(viewModel.selectedFilter.title) 暫時沒有可顯示的動漫新聞。"
                )
            )
                .transition(.opacity)
        case .error(let failure):
            ErrorMessageRetryCardView(
                state: ErrorMessageView.State(failure: failure),
                title: "新聞暫時讀不到",
                retryTitle: "重新載入"
            ) {
                startReload()
            }
            .transition(.opacity)
        case .content(let content), .refreshing(let content):
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(content.rows) { row in
                    MainNewsArticleRowView(row: row) {
                        selectedArticle = row
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .transition(.opacity)
        }
    }

    // MARK: - Private Methods

    private func startReload() {
        reloadTask?.cancel()
        reloadTask = Task {
            await viewModel.reload()
        }
    }
}

#Preview {
    MainNewsView(dependencies: .live)
}
