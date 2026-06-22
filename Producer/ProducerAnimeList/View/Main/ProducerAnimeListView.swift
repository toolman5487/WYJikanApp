//
//  ProducerAnimeListView.swift
//  WYJikanApp
//

import SwiftUI

struct ProducerAnimeListView: View {
    let producerId: Int
    let producerName: String

    var body: some View {
        ProducerAnimeListConfiguredView(
            producerId: producerId,
            producerName: producerName
        )
    }
}

private struct ProducerAnimeListConfiguredView: View {
    @Environment(\.appDependencies) private var dependencies

    let producerId: Int
    let producerName: String

    var body: some View {
        ProducerAnimeListBodyView(
            producerId: producerId,
            producerName: producerName,
            dependencies: dependencies
        )
    }
}

private struct ProducerAnimeListBodyView: View {

    // MARK: - Properties

    @EnvironmentObject private var favoriteStatusStore: FavoriteStatusStore
    @StateObject private var viewModel: ProducerAnimeListViewModel
    @State private var loadMoreBounceProgress: CGFloat = 0

    // MARK: - Initialization

    init(
        producerId: Int,
        producerName: String,
        dependencies: AppDependencies
    ) {
        _viewModel = StateObject(
            wrappedValue: dependencies.makeProducerAnimeListViewModel(
                producerId: producerId,
                producerName: producerName
            )
        )
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                stateContent
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
            loadMore()
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            AnimeCategoryDetailControlBarContainerView(
                selectedSort: $viewModel.selectedSort,
                selectedFormat: $viewModel.selectedFormat
            )
        }
        .navigationTitle(viewModel.producerName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: reload) {
                    Image(systemName: "arrow.trianglehead.counterclockwise")
                        .font(.body.weight(.bold))
                        .foregroundStyle(ThemeColor.sakura)
                        .frame(width: 44, height: 44)
                }
            }
        }
        .task(priority: .userInitiated) {
            await viewModel.loadIfNeeded()
        }
    }

    // MARK: - State Content

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.screenState {
        case .loading:
            AnimeCategoryDetailLoadingView()
        case .empty:
            FeatureEmptyStateCardView(
                emptyState: .emptyCollection(
                    title: "目前沒有相關動畫",
                    message: "MyAnimeList 尚未收錄這間公司的動畫作品。"
                )
            )
        case .error(let failure):
            ErrorMessageRetryCardView(
                state: ErrorMessageView.State(failure: failure),
                title: "相關動畫暫時無法載入",
                retryTitle: "重新載入",
                onRetry: reload
            )
        case .content(let items):
            AnimeCategoryDetailGridSectionView(
                items: items,
                favoriteIDs: favoriteStatusStore.favoriteIDs(for: .anime),
                loadMoreState: viewModel.loadMoreState,
                loadMoreProgress: loadMoreBounceProgress,
                onItemAppear: { _ in },
                onLoadMore: loadMore,
                onRetryLoadMore: retryLoadMore
            )
        }
    }

    // MARK: - Private Methods

    private var canLoadMore: Bool {
        viewModel.loadMoreState == .available
    }

    private func reload() {
        Task(priority: .userInitiated) {
            await viewModel.reload()
        }
    }

    private func loadMore() {
        Task(priority: .userInitiated) {
            await viewModel.loadMore()
        }
    }

    private func retryLoadMore() {
        Task(priority: .userInitiated) {
            await viewModel.retryLoadMore()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProducerAnimeListView(
            producerId: 1,
            producerName: "Studio Pierrot"
        )
    }
}
