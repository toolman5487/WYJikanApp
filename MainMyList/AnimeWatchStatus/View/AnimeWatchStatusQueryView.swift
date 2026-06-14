//
//  AnimeWatchStatusQueryView.swift
//  WYJikanApp
//

import SwiftData
import SwiftUI

struct AnimeWatchStatusQueryView: View {

    // MARK: - Properties

    @StateObject private var viewModel: AnimeWatchStatusQueryViewModel

    // MARK: - Lifecycle

    init(dependencies: AppDependencies) {
        _viewModel = StateObject(
            wrappedValue: dependencies.makeAnimeWatchStatusQueryViewModel()
        )
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                summaryView
                filterView
                contentView
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
        .navigationTitle("動畫觀看狀態")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Private Views

    private var summaryView: some View {
        MyListStatisticsCardContainer(
            title: "觀看總覽",
            subtitle: "\(viewModel.presentation.summary.totalCount) 筆動畫收藏"
        ) {
            HStack(spacing: 8) {
                MyListProgressSummaryChipView(
                    title: "觀看中",
                    count: viewModel.presentation.summary.watchingCount,
                    systemImageName: AnimeWatchStatus.watching.systemImageName
                )
                MyListProgressSummaryChipView(
                    title: "想看",
                    count: viewModel.presentation.summary.plannedCount,
                    systemImageName: AnimeWatchStatus.planned.systemImageName
                )
                MyListProgressSummaryChipView(
                    title: "已看完",
                    count: viewModel.presentation.summary.completedCount,
                    systemImageName: AnimeWatchStatus.completed.systemImageName
                )
            }
        }
    }

    private var filterView: some View {
        CapsuleFilterBarView(
            tags: AnimeWatchStatusFilter.allCases,
            title: { filterTitle(for: $0) },
            systemImageName: { $0.systemImageName },
            selection: $viewModel.selectedFilter
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.presentation.filteredItems.isEmpty {
            MyListEmptyStateView(
                emptyState: .filteredEmpty(
                    title: "沒有符合的動畫",
                    message: "切換觀看狀態查看其他收藏。"
                )
            )
        } else {
            LazyVStack(spacing: 12) {
                ForEach(
                    viewModel.presentation.filteredItems,
                    id: \.persistentModelID
                ) { item in
                    NavigationLink {
                        AnimeDetailView(malId: item.malId)
                    } label: {
                        MyListItemRowView(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Private Methods

    private func filterTitle(for filter: AnimeWatchStatusFilter) -> String {
        guard
            let count = viewModel.presentation.summary.statusCounts.first(
                where: { $0.filter == filter }
            )?.count
        else {
            return filter.title
        }

        return "\(filter.title) \(count)"
    }
}
