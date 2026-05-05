//
//  HomeTrendingAnimeListView.swift
//  WYJikanApp
//
//  Created by Willy Hsu 2026/5/5.
//

import SwiftUI

struct HomeTrendingAnimeListView: View {
    @StateObject private var viewModel: HomeTrendingAnimeListViewModel
    @EnvironmentObject private var router: MainHomeRouter

    init(viewModel: HomeTrendingAnimeListViewModel = HomeTrendingAnimeListViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
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

    @ViewBuilder
    private var stateContentView: some View {
        switch viewModel.screenState {
        case .loading:
            HomeTrendingAnimeListLoadingView()
        case .empty:
            HomeTrendingAnimeListEmptyStateView()
        case .error(let message):
            HomeTrendingAnimeListErrorStateView(message: message) {
                Task { await viewModel.reload() }
            }
        case .content(let content):
            VStack(alignment: .leading, spacing: 22) {
                if let featuredSection = content.featuredSection {
                    HomeTrendingAnimeListFeaturedSectionView(
                        title: featuredSection.title,
                        items: featuredSection.items,
                        onTap: { item in
                            router.push(.animeDetail(malId: item.id))
                        }
                    )
                }

                HomeTrendingAnimeListRankedSectionView(
                    title: content.rankedSection.title,
                    countText: content.rankedSection.countText,
                    items: content.rankedSection.items,
                    loadMoreState: viewModel.loadMoreState,
                    onItemAppear: { item in
                        Task { await viewModel.loadMoreIfNeeded(currentItem: item) }
                    },
                    onTapItem: { item in
                        router.push(.animeDetail(malId: item.id))
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
}
