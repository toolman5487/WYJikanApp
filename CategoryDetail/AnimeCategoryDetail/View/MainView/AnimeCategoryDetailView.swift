//
//  AnimeCategoryDetailView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/5/2.
//

import SwiftUI

struct AnimeCategoryDetailView: View {
    @StateObject private var viewModel: AnimeCategoryDetailViewModel

    init(
        genre: AnimeListGenreDTO,
        service: AnimeCategoryDetailServicing = AnimeCategoryDetailService()
    ) {
        _viewModel = StateObject(
            wrappedValue: AnimeCategoryDetailViewModel(genre: genre, service: service)
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                AnimeCategoryDetailHeaderView(
                    title: viewModel.genreTitle,
                    subtitle: viewModel.headerSubtitle,
                    loadedCountText: viewModel.loadedCountText
                )
                AnimeCategoryDetailControlBarView(
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
            AnimeCategoryDetailLoadingView()
        case .empty:
            AnimeCategoryDetailEmptyStateView()
        case let .error(message):
            AnimeCategoryDetailErrorStateView(message: message) {
                Task { await viewModel.reload() }
            }
        case let .content(items):
            AnimeCategoryDetailGridSectionView(
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
        AnimeCategoryDetailView(genre: AnimeListGenreDTO(malId: 1, name: "Action"))
    }
}
