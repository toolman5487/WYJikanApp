//
//  HomeTrendingAnimeListView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/5/5.
//

import SwiftUI

// MARK: - HomeTrendingAnimeListView

struct HomeTrendingAnimeListView: View {
    var body: some View {
        HomeTrendingAnimeListConfiguredView()
    }
}

private struct HomeTrendingAnimeListConfiguredView: View {
    @Environment(\.appDependencies) private var dependencies

    var body: some View {
        HomeTrendingAnimeListBodyView(dependencies: dependencies)
    }
}

private struct HomeTrendingAnimeListBodyView: View {

    // MARK: - Properties

    @EnvironmentObject private var router: MainHomeRouter
    @EnvironmentObject private var favoriteStatusStore: FavoriteStatusStore

    @StateObject private var viewModel: HomeTrendingAnimeListViewModel
    @State private var loadMoreBounceProgress: CGFloat = 0

    // MARK: - Lifecycle

    init(dependencies: AppDependencies) {
        _viewModel = StateObject(
            wrappedValue: dependencies.makeHomeTrendingAnimeListViewModel()
        )
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8, pinnedViews: [.sectionHeaders]) {
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
            Task { await viewModel.loadMore() }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HomeTrendingAnimeListControlBarContainerView(
                items: viewModel.sortChipItems,
                onSelectSort: viewModel.selectSort(_:)
            )
        }
        .navigationTitle("熱門動畫")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
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
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    // MARK: - Private Methods

    @ViewBuilder
    private var stateContentView: some View {
        switch viewModel.screenState {
        case .loading:
            HomeTrendingAnimeListLoadingView()
                .transition(.opacity.combined(with: .move(edge: .bottom)))

        case .empty:
            FeatureEmptyStateCardView(
                emptyState: .emptyCollection(
                    title: "目前還沒有熱門動畫資料",
                    message: "稍後再回來看看，榜單更新後就會顯示在這裡。"
                )
            )
                .transition(.opacity.combined(with: .move(edge: .bottom)))

        case .error(let failure):
            ErrorMessageRetryCardView(
                state: ErrorMessageView.State(failure: failure),
                title: "熱門榜單暫時讀不到",
                retryTitle: "重新載入"
            ) {
                Task { await viewModel.reload() }
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))

        case .content(let content):
            sectionListView(sections: content.sections)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    private func sectionListView(sections: [HomeTrendingAnimeListSectionContent]) -> some View {
        let favoriteIDs = favoriteStatusStore.favoriteIDs(for: .anime)

        return LazyVStack(alignment: .leading, spacing: 8, pinnedViews: [.sectionHeaders]) {
            ForEach(sections) { section in
                Section {
                    ForEach(section.items) { item in
                        HomeTrendingAnimeListRowView(
                            item: item,
                            sort: viewModel.selectedSort,
                            isFavorite: favoriteIDs.contains(item.id)
                        ) {
                            router.push(.animeDetail(malId: item.id))
                        }
                    }
                } header: {
                    sectionHeaderView(section)
                }
            }

            HomeTrendingAnimeListLoadMoreFooterView(
                state: viewModel.loadMoreState,
                progress: loadMoreBounceProgress,
                onLoadMore: {
                    Task { await viewModel.loadMore() }
                },
                onRetry: {
                    Task { await viewModel.retryLoadMore() }
                }
            )
        }
    }

    private func sectionHeaderView(_ section: HomeTrendingAnimeListSectionContent) -> some View {
        GlassSectionHeaderView(
            title: section.title,
            outerVerticalPadding: 0
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
