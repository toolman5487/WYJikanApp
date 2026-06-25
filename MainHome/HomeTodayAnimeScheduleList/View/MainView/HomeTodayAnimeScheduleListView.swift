//
//  HomeTodayAnimeScheduleListView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/4.
//

import SwiftUI

// MARK: - HomeTodayAnimeScheduleListView

struct HomeTodayAnimeScheduleListView: View {
    var body: some View {
        HomeTodayAnimeScheduleListConfiguredView()
    }
}

private struct HomeTodayAnimeScheduleListConfiguredView: View {
    @Environment(\.appDependencies) private var dependencies

    var body: some View {
        HomeTodayAnimeScheduleListBodyView(dependencies: dependencies)
    }
}

private struct HomeTodayAnimeScheduleListBodyView: View {
    private enum Layout {
        static let pageHorizontalPadding: CGFloat = 16
        static let pageTopPadding: CGFloat = 16
        static let pageBottomPadding: CGFloat = 32
        static let contentSpacing: CGFloat = 16
        static let rowSpacing: CGFloat = 12
        static let toolbarButtonSize: CGFloat = 44
    }

    // MARK: - Properties

    @EnvironmentObject private var router: MainHomeRouter
    @EnvironmentObject private var favoriteStatusStore: FavoriteStatusStore
    @StateObject private var viewModel: HomeTodayAnimeScheduleListViewModel

    // MARK: - Lifecycle

    init(dependencies: AppDependencies) {
        _viewModel = StateObject(
            wrappedValue: dependencies.makeHomeTodayAnimeScheduleListViewModel()
        )
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Layout.contentSpacing, pinnedViews: [.sectionHeaders]) {
                HomeTodayAnimeScheduleListHeaderView(
                    title: viewModel.headerTitle,
                    subtitle: viewModel.headerSubtitle,
                    loadedCountText: viewModel.loadedCountText
                )
                stateContentView
            }
            .padding(.horizontal, Layout.pageHorizontalPadding)
            .padding(.top, Layout.pageTopPadding)
            .padding(.bottom, Layout.pageBottomPadding)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HomeTodayAnimeScheduleListDayFilterContainerView(
                selectedDay: viewModel.selectedDay,
                onSelectDay: viewModel.updateSelectedDay(_:)
            )
        }
        .navigationTitle("播出時間表")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task(priority: .userInitiated) { await viewModel.reload() }
                } label: {
                    Image(systemName: "arrow.trianglehead.counterclockwise")
                        .font(.body.weight(.bold))
                        .foregroundStyle(ThemeColor.sakura)
                        .frame(width: Layout.toolbarButtonSize, height: Layout.toolbarButtonSize)
                }
            }
        }
        .requestScreenTabLifecycle(viewModel: viewModel)
    }

    @ViewBuilder
    private var stateContentView: some View {
        switch viewModel.screenState {
        case .loading:
            HomeTodayAnimeScheduleListLoadingView()
                .transition(.opacity.combined(with: .move(edge: .bottom)))

        case .empty:
            FeatureEmptyStateCardView(
                emptyState: .emptyCollection(
                    title: "這天目前沒有可顯示的 TV 動畫",
                    message: "可以切換其他星期，或稍後再回來看看。"
                )
            )
                .transition(.opacity.combined(with: .move(edge: .bottom)))

        case .error(let failure):
            ErrorMessageRetryCardView(
                state: ErrorMessageView.State(failure: failure),
                title: "播出表暫時讀不到",
                retryTitle: "重新載入"
            ) {
                Task(priority: .userInitiated) { await viewModel.reload() }
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))

        case .content(let sections):
            timelineListView(sections: sections)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    private func timelineListView(sections: [HomeTodayAnimeTimeSection]) -> some View {
        let favoriteIDs = favoriteStatusStore.favoriteIDs(for: .anime)

        return LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
            ForEach(sections) { section in
                Section {
                    VStack(spacing: Layout.rowSpacing) {
                        ForEach(section.items) { item in
                            HomeTodayAnimeScheduleListTimelineRowView(
                                item: item,
                                isFavorite: favoriteIDs.contains(item.id)
                            ) {
                                router.push(.animeDetail(malId: item.id))
                            }
                            .onAppear {
                                Task(priority: .userInitiated) {
                                    await viewModel.loadMoreIfNeeded(currentItem: item)
                                }
                            }
                        }
                    }
                    .padding(.bottom, Layout.contentSpacing)
                } header: {
                    HomeTodayAnimeScheduleListSectionHeaderView(section: section)
                }
            }

            HomeTodayAnimeScheduleListLoadMoreFooterView(
                state: viewModel.loadMoreState,
                onLoadMore: {
                    Task(priority: .userInitiated) { await viewModel.loadMore() }
                },
                onRetry: {
                    Task(priority: .userInitiated) { await viewModel.retryLoadMore() }
                }
            )
        }
    }
}

#Preview {
    NavigationStack {
        HomeTodayAnimeScheduleListView()
            .environmentObject(FavoriteStatusStore())
            .environmentObject(MainHomeRouter())
    }
}
