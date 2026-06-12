//
//  HomeTrendingMangaListView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/6.
//

import SwiftUI

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
            VStack(alignment: .leading, spacing: 8) {
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
            Task { await viewModel.loadMore() }
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
            MangaCategoryDetailLoadingView()

        case .empty:
            VStack(alignment: .leading, spacing: 16) {
                emptyStateCard

                MangaCategoryDetailLoadMoreFooterView(
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

        case .error(let failure):
            errorStateCard(message: failure.message)

        case .content(let items):
            MangaCategoryDetailGridSectionView(
                items: items,
                favoriteIDs: favoriteStatusStore.favoriteIDs(for: .manga),
                loadMoreState: viewModel.loadMoreState,
                loadMoreProgress: loadMoreBounceProgress,
                onItemAppear: { _ in
                },
                onLoadMore: {
                    Task { await viewModel.loadMore() }
                },
                onRetryLoadMore: {
                    Task { await viewModel.retryLoadMore() }
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
        VStack(alignment: .leading, spacing: 12) {
            Text(emptyStateTitle)
                .font(.title3.weight(.bold))
                .foregroundStyle(ThemeColor.textPrimary)

            Text(emptyStateSubtitle)
                .font(.body)
                .foregroundStyle(ThemeColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .center)
        .padding(24)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func errorStateCard(message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("熱門漫畫榜單暫時讀不到")
                .font(.title3.weight(.bold))
                .foregroundStyle(ThemeColor.textPrimary)

            Text(message)
                .font(.body)
                .foregroundStyle(ThemeColor.textSecondary)

            Button("重新載入") {
                Task { await viewModel.reload() }
            }
            .buttonStyle(.borderedProminent)
            .tint(ThemeColor.sakura)
        }
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .center)
        .padding(24)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
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
