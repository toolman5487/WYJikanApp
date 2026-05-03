//
//  MangaCategoryDetailView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/5/2.
//

import SwiftUI

struct MangaCategoryDetailView: View {
    @StateObject private var viewModel: MangaCategoryDetailViewModel

    init(
        genre: MangaListGenreDTO,
        service: MangaCategoryDetailServicing = MangaCategoryDetailService()
    ) {
        _viewModel = StateObject(
            wrappedValue: MangaCategoryDetailViewModel(genre: genre, service: service)
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
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
        .navigationTitle(viewModel.genreTitle)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
        .task {
            await viewModel.loadIfNeeded()
        }
    }

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

#Preview {
    NavigationStack {
        MangaCategoryDetailView(genre: MangaListGenreDTO(malId: 1, name: "Action"))
    }
}
