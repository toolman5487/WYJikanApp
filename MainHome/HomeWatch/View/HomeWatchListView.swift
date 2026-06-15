//
//  HomeWatchListView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/9.
//

import SwiftUI

// MARK: - HomeWatchListView

struct HomeWatchListView: View {

    // MARK: - Properties

    @EnvironmentObject private var router: MainHomeRouter
    @EnvironmentObject private var favoriteStatusStore: FavoriteStatusStore

    @StateObject private var viewModel: HomeWatchListViewModel
    @State private var loadMoreBounceProgress: CGFloat = 0

    // MARK: - Lifecycle

    init(viewModel: HomeWatchListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                let header = viewModel.headerContent
                HomeTrendingAnimeListHeaderView(
                    title: header.title,
                    subtitle: header.subtitle,
                    loadedCountText: header.loadedCountText
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
            HomeWatchFeedControlBarContainerView(
                items: viewModel.feedChipItems,
                onSelectFeed: viewModel.selectFeed(_:)
            )
        }
        .navigationTitle("影音")
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
            HomeWatchListLoadingView()
                .transition(.opacity.combined(with: .move(edge: .bottom)))

        case .empty:
            FeatureEmptyStateCardView(
                emptyState: .emptyCollection(
                    title: "目前沒有可顯示的影音資料",
                    message: "稍後重新整理，或切換其他分類查看。"
                ),
                minHeight: 0,
                alignment: .leading
            )
                .transition(.opacity.combined(with: .move(edge: .bottom)))

        case .error(let failure):
            ErrorMessageRetryCardView(
                state: ErrorMessageView.State(failure: failure),
                title: "影音資料載入失敗",
                retryTitle: "重新整理",
                onRetry: {
                    Task(priority: .userInitiated) { await viewModel.reload() }
                },
                minHeight: 0,
                alignment: .leading
            )
            .transition(.opacity.combined(with: .move(edge: .bottom)))

        case .content(let items):
            listView(items: items)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    private func listView(items: [HomeWatchListItem]) -> some View {
        let favoriteIDs = favoriteStatusStore.favoriteIDs(for: .anime)

        return LazyVStack(alignment: .leading, spacing: 12) {
            ForEach(items) { item in
                HomeWatchListRowView(
                    item: item,
                    isFavorite: favoriteIDs.contains(item.animeID)
                ) {
                    open(item)
                }
            }

            HomeWatchListLoadMoreFooterView(
                state: viewModel.loadMoreState,
                progress: loadMoreBounceProgress,
                onLoadMore: {
                    Task(priority: .userInitiated) { await viewModel.loadMore() }
                },
                onRetry: {
                    Task(priority: .userInitiated) { await viewModel.retryLoadMore() }
                }
            )
        }
    }

    private func open(_ item: HomeWatchListItem) {
        switch (item.contentKind, item.actionURL) {
        case (.episode, .some(let actionURL)):
            open(.watchEpisode(url: actionURL))

        case (.promo, .some(let actionURL)):
            openExternally(.watchPromo(url: actionURL))

        case (.episode, .none), (.promo, .none):
            router.push(.animeDetail(malId: item.animeID))
        }
    }

    private func open(_ page: BaseWebPage) {
        if page.opensExternally {
            openExternally(page)
        } else {
            router.push(.webPage(page))
        }
    }

    private func openExternally(_ page: BaseWebPage) {
        ExternalURLOpener.open(page.externalURLCandidates)
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
    HomeWatchListView(
        viewModel: AppDependencies.live.makeHomeWatchListViewModel(initialFeed: .latestPromos)
    )
    .environmentObject(FavoriteStatusStore())
    .environmentObject(MainHomeRouter())
}
