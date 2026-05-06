//
//  HomeTrendingMangaListView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/6.
//

import SwiftUI

struct HomeTrendingMangaListView: View {
    @StateObject private var viewModel: HomeTrendingMangaListViewModel

    init(viewModel: HomeTrendingMangaListViewModel = HomeTrendingMangaListViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
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
            .allowsHitTesting(!viewModel.isApplyingMenuSelection)

            if viewModel.isApplyingMenuSelection {
                applyingSelectionOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HomeTrendingMangaListControlBarContainerView(
                selectedSort: $viewModel.selectedSort,
                selectedFormat: $viewModel.selectedFormat
            )
            .disabled(viewModel.isApplyingMenuSelection)
        }
        .navigationTitle("熱門漫畫")
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
                    onLoadMore: {
                        Task { await viewModel.loadMore() }
                    },
                    onRetry: {
                        Task { await viewModel.retryLoadMore() }
                    }
                )
            }
        case .error(let message):
            errorStateCard(message: message)
        case .content(let items):
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

    private var emptyStateCard: some View {
        VStack(alignment: .leading, spacing: 10) {
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
        VStack(alignment: .leading, spacing: 10) {
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

    private var applyingSelectionOverlay: some View {
        ZStack {
            Color(.systemBackground)
                .opacity(0.92)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                Text("更新榜單中...")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ThemeColor.textSecondary)

                MangaCategoryDetailLoadingView()
            }
            .padding(20)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 16, y: 8)
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    NavigationStack {
        HomeTrendingMangaListView()
    }
}
