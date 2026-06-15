//
//  MangaCategoryDetailView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/5/2.
//

import SwiftUI

struct MangaCategoryDetailView: View {
    let genre: MangaListGenreDTO

    var body: some View {
        MangaCategoryDetailConfiguredView(genre: genre)
    }
}

private struct MangaCategoryDetailConfiguredView: View {
    @Environment(\.appDependencies) private var dependencies
    let genre: MangaListGenreDTO

    var body: some View {
        MangaCategoryDetailBodyView(genre: genre, dependencies: dependencies)
    }
}

private struct MangaCategoryDetailBodyView: View {

    // MARK: - Properties

    @EnvironmentObject private var favoriteStatusStore: FavoriteStatusStore
    @StateObject private var viewModel: MangaCategoryDetailViewModel
    @State private var loadMoreBounceProgress: CGFloat = 0

    // MARK: - Initialization

    init(genre: MangaListGenreDTO, dependencies: AppDependencies) {
        _viewModel = StateObject(
            wrappedValue: dependencies.makeMangaCategoryDetailViewModel(genre: genre)
        )
    }

    // MARK: - Body

    var body: some View {
        scrollContent
            .navigationTitle(viewModel.genreTitle)
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemBackground))
            .task(priority: .userInitiated) {
                await viewModel.loadIfNeeded()
            }
    }

    // MARK: - Scroll Content

    private var scrollContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8, pinnedViews: [.sectionHeaders]) {
                MangaCategoryDetailHeaderView(
                    title: viewModel.genreTitle,
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
            MangaCategoryDetailControlBarContainerView(
                selectedSort: $viewModel.selectedSort,
                selectedFormat: $viewModel.selectedFormat
            )
        }
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
    }

    // MARK: - State Content

    @ViewBuilder
    private var stateContentView: some View {
        switch viewModel.screenState {
        case .loading:
            MangaCategoryDetailLoadingView()

        case .empty:
            FeatureEmptyStateCardView(
                emptyState: .emptyCollection(
                    title: "這個分類目前還沒有作品",
                    message: "可以先回到首頁看看其他分類，或稍後再回來探索。"
                )
            )

        case let .error(failure):
            ErrorMessageRetryCardView(
                state: ErrorMessageView.State(failure: failure),
                title: "這個分類暫時打不開",
                retryTitle: "重新載入"
            ) {
                Task(priority: .userInitiated) { await viewModel.reload() }
            }

        case let .content(items):
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

    private var canLoadMore: Bool {
        switch viewModel.loadMoreState {
        case .available:
            return true
        case .hidden, .loading, .error:
            return false
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MangaCategoryDetailView(genre: MangaListGenreDTO(malId: 1, name: "Action"))
    }
}
