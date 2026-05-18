//
//  HomeTrendingAnimeListView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/5/5.
//

import SwiftUI

struct HomeTrendingAnimeListView: View {

    // MARK: - Properties

    @EnvironmentObject private var router: MainHomeRouter
    @EnvironmentObject private var favoriteStatusStore: FavoriteStatusStore

    @StateObject private var viewModel: HomeTrendingAnimeListViewModel

    // MARK: - Lifecycle

    init(viewModel: HomeTrendingAnimeListViewModel = HomeTrendingAnimeListViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24, pinnedViews: [.sectionHeaders]) {
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
        .allowsHitTesting(!viewModel.isApplyingMenuSelection)
        .overlay {
            if viewModel.isApplyingMenuSelection {
                applyingSelectionOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HomeTrendingAnimeListControlBarContainerView(
                items: viewModel.sortChipItems,
                onSelectSort: viewModel.selectSort(_:)
            )
            .disabled(viewModel.isApplyingMenuSelection)
        }
        .navigationTitle("熱門動畫")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
        .animation(.easeInOut(duration: 0.2), value: viewModel.isApplyingMenuSelection)
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
            HomeTrendingAnimeListEmptyStateView()
                .transition(.opacity.combined(with: .move(edge: .bottom)))

        case .error(let message):
            HomeTrendingAnimeListErrorStateView(message: message) {
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

        return LazyVStack(alignment: .leading, spacing: 20, pinnedViews: [.sectionHeaders]) {
            ForEach(sections) { section in
                Section {
                    VStack(spacing: 12) {
                        ForEach(section.items) { item in
                            HomeTrendingAnimeListRowView(
                                item: item,
                                sort: viewModel.selectedSort,
                                isFavorite: favoriteIDs.contains(item.id)
                            ) {
                                router.push(.animeDetail(malId: item.id))
                            }
                        }
                    }
                } header: {
                    sectionHeaderView(section)
                }
            }

            HomeTrendingAnimeListLoadMoreFooterView(
                state: viewModel.loadMoreState,
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
        GlassSectionHeaderView(title: section.title)
    }

    private var applyingSelectionOverlay: some View {
        ZStack {
            Color(.systemBackground)
                .opacity(0.92)

            VStack(alignment: .leading, spacing: 20) {
                Text("更新榜單中...")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ThemeColor.textSecondary)

                HomeTrendingAnimeListLoadingView()
            }
            .padding(20)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 16, y: 8)
            .padding(.horizontal, 16)
        }
        .safeAreaPadding(.top)
    }
}
