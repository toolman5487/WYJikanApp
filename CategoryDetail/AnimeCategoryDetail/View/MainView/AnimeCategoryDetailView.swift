//
//  AnimeCategoryDetailView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/5/2.
//

import SwiftUI

struct AnimeCategoryDetailView: View {
    let genre: AnimeListGenreDTO

    var body: some View {
        AnimeCategoryDetailConfiguredView(genre: genre)
    }
}

private struct AnimeCategoryDetailConfiguredView: View {
    @Environment(\.appDependencies) private var dependencies
    let genre: AnimeListGenreDTO

    var body: some View {
        AnimeCategoryDetailBodyView(genre: genre, dependencies: dependencies)
    }
}

private struct AnimeCategoryDetailBodyView: View {

    // MARK: - Properties

    @EnvironmentObject private var favoriteStatusStore: FavoriteStatusStore
    @StateObject private var viewModel: AnimeCategoryDetailViewModel
    @State private var loadMoreBounceProgress: CGFloat = 0

    // MARK: - Initialization

    init(genre: AnimeListGenreDTO, dependencies: AppDependencies) {
        _viewModel = StateObject(
            wrappedValue: dependencies.makeAnimeCategoryDetailViewModel(genre: genre)
        )
    }

    // MARK: - Body

    var body: some View {
        scrollContent
            .navigationTitle(viewModel.genreTitle)
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemBackground))
            .task {
                await viewModel.loadIfNeeded()
            }
    }

    // MARK: - Scroll Content

    private var scrollContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8, pinnedViews: [.sectionHeaders]) {
                AnimeCategoryDetailHeaderView(
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
            Task { await viewModel.loadMore() }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            AnimeCategoryDetailControlBarContainerView(
                selectedSort: $viewModel.selectedSort,
                selectedFormat: $viewModel.selectedFormat
            )
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
            }
        }
    }

    // MARK: - State Content

    @ViewBuilder
    private var stateContentView: some View {
        switch viewModel.screenState {
        case .loading:
            AnimeCategoryDetailLoadingView()

        case .empty:
            AnimeCategoryDetailEmptyStateView()

        case let .error(failure):
            AnimeCategoryDetailErrorStateView(message: failure.message) {
                Task { await viewModel.reload() }
            }

        case let .content(items):
            AnimeCategoryDetailGridSectionView(
                items: items,
                favoriteIDs: favoriteStatusStore.favoriteIDs(for: .anime),
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
        AnimeCategoryDetailView(genre: AnimeListGenreDTO(malId: 1, name: "Action"))
    }
}
