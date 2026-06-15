//
//  HomeTrendingMangaListView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/6.
//

import SwiftUI

// MARK: - HomeTrendingMangaListView

struct HomeTrendingMangaListView: View {
    var body: some View {
        HomeTrendingMangaListConfiguredView()
    }
}

private struct HomeTrendingMangaListConfiguredView: View {
    @Environment(\.appDependencies) private var dependencies

    var body: some View {
        HomeTrendingMangaListBodyView(dependencies: dependencies)
    }
}

private struct HomeTrendingMangaListBodyView: View {

    // MARK: - Properties

    @EnvironmentObject private var favoriteStatusStore: FavoriteStatusStore
    @StateObject private var viewModel: HomeTrendingMangaListViewModel
    @State private var loadMoreBounceProgress: CGFloat = 0

    // MARK: - Lifecycle

    init(dependencies: AppDependencies) {
        _viewModel = StateObject(
            wrappedValue: dependencies.makeHomeTrendingMangaListViewModel()
        )
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                HomeTrendingAnimeListHeaderView(
                    title: viewModel.headerTitle,
                    subtitle: viewModel.headerSubtitle,
                    loadedCountText: viewModel.loadedCountText
                )
                stateContentView
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .onEndBounce(
            axis: .vertical,
            isEnabled: canLoadMore,
            threshold: 16,
            revealDistance: 220,
            progress: $loadMoreBounceProgress
        ) {
            Task(priority: .userInitiated) { await viewModel.loadMore() }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HomeTrendingMangaListControlBarContainerView(
                selectedSort: $viewModel.selectedSort,
                selectedFormat: $viewModel.selectedFormat
            )
        }
        .navigationTitle("熱門漫畫")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task(priority: .userInitiated) { await viewModel.reload() }
                } label: {
                    Image(systemName: "arrow.trianglehead.counterclockwise")
                        .font(.body.weight(.bold))
                        .foregroundStyle(ThemeColor.sakura)
                        .frame(width: 44, height: 44)
                }
            }
        }
        .task(priority: .userInitiated) {
            await viewModel.loadIfNeeded()
        }
    }

    // MARK: - Private Methods

    @ViewBuilder
    private var stateContentView: some View {
        switch viewModel.screenState {
        case .loading:
            RankedMediaListLoadingView()

        case .empty:
            VStack(alignment: .leading, spacing: 16) {
                emptyStateCard

                PaginationLoadMoreFooterView(
                    state: viewModel.loadMoreState,
                    availablePresentation: .endBounceHint(
                        title: "載入更多作品",
                        subtitle: "繼續往下拉展開更多",
                        progress: loadMoreBounceProgress
                    ),
                    onAvailableTap: {
                        Task(priority: .userInitiated) { await viewModel.loadMore() }
                    },
                    onRetry: {
                        Task(priority: .userInitiated) { await viewModel.retryLoadMore() }
                    }
                )
            }

        case .error(let failure):
            ErrorMessageRetryCardView(
                state: ErrorMessageView.State(failure: failure),
                title: "熱門漫畫榜單暫時讀不到",
                retryTitle: "重新載入"
            ) {
                Task(priority: .userInitiated) { await viewModel.reload() }
            }

        case .content(let items):
            MangaCategoryDetailGridSectionView(
                items: items,
                favoriteIDs: favoriteStatusStore.favoriteIDs(for: .manga),
                loadMoreState: viewModel.loadMoreState,
                loadMoreProgress: loadMoreBounceProgress,
                onItemAppear: { _ in
                },
                onLoadMore: {
                    Task(priority: .userInitiated) { await viewModel.loadMore() }
                },
                onRetryLoadMore: {
                    Task(priority: .userInitiated) { await viewModel.retryLoadMore() }
                }
            )
        }
    }

    private var emptyStateTitle: String {
        if viewModel.selectedFormat == .all {
            return "目前還沒有熱門漫畫資料"
        }
        return "目前沒有符合條件的熱門漫畫"
    }

    private var emptyStateSubtitle: String {
        if viewModel.selectedFormat == .all {
            return "稍後再回來看看，榜單更新後就會顯示在這裡。"
        }
        return "可以先切回「全部」，或繼續載入更多作品看看。"
    }

    private var emptyStateCard: some View {
        FeatureEmptyStateCardView(
            emptyState: viewModel.selectedFormat == .all
                ? .emptyCollection(title: emptyStateTitle, message: emptyStateSubtitle)
                : .filteredEmpty(title: emptyStateTitle, message: emptyStateSubtitle)
        )
    }

    private var canLoadMore: Bool {
        switch viewModel.loadMoreState {
        case .available:
            return true
        case .hidden, .loading, .error:
            return false
        }
    }
}

#Preview {
    NavigationStack {
        HomeTrendingMangaListView()
    }
}
