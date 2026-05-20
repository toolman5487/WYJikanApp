//
//  HomeTodayAnimeScheduleListView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/4.
//

import SwiftUI

struct HomeTodayAnimeScheduleListView: View {

    // MARK: - Properties

    @EnvironmentObject private var router: MainHomeRouter
    @EnvironmentObject private var favoriteStatusStore: FavoriteStatusStore
    @StateObject private var viewModel: HomeTodayAnimeScheduleListViewModel

    // MARK: - Lifecycle

    init(viewModel: HomeTodayAnimeScheduleListViewModel = HomeTodayAnimeScheduleListViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24, pinnedViews: [.sectionHeaders]) {
                HomeTodayAnimeScheduleListHeaderView(
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
            HomeTodayAnimeScheduleListLoadingView()
                .transition(.opacity.combined(with: .move(edge: .bottom)))

        case .empty:
            HomeTodayAnimeScheduleListEmptyStateView()
                .transition(.opacity.combined(with: .move(edge: .bottom)))

        case .error(let message):
            HomeTodayAnimeScheduleListErrorStateView(message: message) {
                Task { await viewModel.reload() }
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))

        case .content(let sections):
            timelineListView(sections: sections)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    private func timelineListView(sections: [HomeTodayAnimeTimeSection]) -> some View {
        let favoriteIDs = favoriteStatusStore.favoriteIDs(for: .anime)

        return LazyVStack(alignment: .leading, spacing: 20, pinnedViews: [.sectionHeaders]) {
            ForEach(sections) { section in
                Section {
                    VStack(spacing: 12) {
                        ForEach(section.items) { item in
                            HomeTodayAnimeScheduleListTimelineRowView(
                                item: item,
                                isFavorite: favoriteIDs.contains(item.id)
                            ) {
                                router.push(.animeDetail(malId: item.id))
                            }
                            .onAppear {
                                Task {
                                    await viewModel.loadMoreIfNeeded(currentItem: item)
                                }
                            }
                        }
                    }
                } header: {
                    HomeTodayAnimeScheduleListSectionHeaderView(section: section)
                }
            }

            HomeTodayAnimeScheduleListLoadMoreFooterView(
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
}

#Preview {
    NavigationStack {
        HomeTodayAnimeScheduleListView()
            .environmentObject(FavoriteStatusStore())
            .environmentObject(MainHomeRouter())
    }
}
