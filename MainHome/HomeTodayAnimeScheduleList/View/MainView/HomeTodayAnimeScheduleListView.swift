//
//  HomeTodayAnimeScheduleListView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/4.
//

import SwiftUI

struct HomeTodayAnimeScheduleListView: View {
    @StateObject private var viewModel: HomeTodayAnimeScheduleListViewModel
    @EnvironmentObject private var router: MainHomeRouter

    init(viewModel: HomeTodayAnimeScheduleListViewModel = HomeTodayAnimeScheduleListViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 22, pinnedViews: [.sectionHeaders]) {
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
                onSelectDay: handleDaySelection(_:)
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
        .animation(.easeInOut(duration: 0.22), value: viewModel.selectedDay)
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
        LazyVStack(alignment: .leading, spacing: 18, pinnedViews: [.sectionHeaders]) {
            ForEach(sections) { section in
                Section {
                    VStack(spacing: 12) {
                        ForEach(section.items) { item in
                            HomeTodayAnimeScheduleListTimelineRowView(item: item) {
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

    private func handleDaySelection(_ day: HomeScheduleDay) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            viewModel.selectedDay = day
        }
    }
}

#Preview {
    NavigationStack {
        HomeTodayAnimeScheduleListView()
            .environmentObject(MainHomeRouter())
    }
}
