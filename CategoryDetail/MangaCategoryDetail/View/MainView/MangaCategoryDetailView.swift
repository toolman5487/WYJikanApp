//
//  MangaCategoryDetailView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/5/2.
//

import SwiftUI

struct MangaCategoryDetailView: View {

    // MARK: - Properties

    @StateObject private var viewModel: MangaCategoryDetailViewModel

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
            VStack(alignment: .leading, spacing: 24) {
                MangaCategoryDetailHeaderView(
                    title: viewModel.genreTitle,
                    subtitle: viewModel.headerSubtitle,
                    loadedCountText: viewModel.loadedCountText
                )
                MangaCategoryDetailControlBarView(
                    selectedSort: $viewModel.selectedSort,
                    selectedFormat: $viewModel.selectedFormat
                )
                stateContentView
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 28)
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
                loadMoreState: viewModel.loadMoreState,
                onItemAppear: { item in
                    Task { await viewModel.loadMoreIfNeeded(currentItem: item) }
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
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MangaCategoryDetailView(genre: MangaListGenreDTO(malId: 1, name: "Action"))
    }
}
