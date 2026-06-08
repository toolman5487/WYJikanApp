//
//  MangaCategoryDetailView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/5/2.
//

import SwiftUI

struct MangaCategoryDetailView: View {

    // MARK: - Properties

    @EnvironmentObject private var favoriteStatusStore: FavoriteStatusStore
    @StateObject private var viewModel: MangaCategoryDetailViewModel
    @State private var loadMoreBounceProgress: CGFloat = 0

    // MARK: - Initialization

    init(
        genre: MangaListGenreDTO,
        service: MangaCategoryDetailServicing = MangaCategoryDetailService()
    ) {
        _viewModel = StateObject(
            wrappedValue: MangaCategoryDetailViewModel(genre: genre, service: service)
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
            threshold: 36,
            revealDistance: 144,
            progress: $loadMoreBounceProgress
        ) {
            Task { await viewModel.loadMore() }
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
            MangaCategoryDetailLoadingView()

        case .empty:
            MangaCategoryDetailEmptyStateView()

        case let .error(message):
            MangaCategoryDetailErrorStateView(message: message) {
                Task { await viewModel.reload() }
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
        MangaCategoryDetailView(genre: MangaListGenreDTO(malId: 1, name: "Action"))
    }
}
