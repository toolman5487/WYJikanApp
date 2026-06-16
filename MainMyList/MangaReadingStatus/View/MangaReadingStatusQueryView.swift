//
//  MangaReadingStatusQueryView.swift
//  WYJikanApp
//

import SwiftData
import SwiftUI

struct MangaReadingStatusQueryView: View {

    // MARK: - Types

    private enum Layout {
        static let sectionSpacing: CGFloat = 20
        static let rowSpacing: CGFloat = 12
        static let horizontalPadding: CGFloat = 20
        static let topPadding: CGFloat = 20
        static let bottomPadding: CGFloat = 32
    }

    // MARK: - Properties

    @StateObject private var viewModel: MangaReadingStatusQueryViewModel

    // MARK: - Lifecycle

    init(dependencies: AppDependencies) {
        _viewModel = StateObject(
            wrappedValue: dependencies.makeMangaReadingStatusQueryViewModel()
        )
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                summaryView
                filterView
                contentView
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, Layout.topPadding)
            .padding(.bottom, Layout.bottomPadding)
        }
        .background(Color(.systemBackground))
        .navigationTitle("漫畫閱讀狀態")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Private Views

    private var summaryView: some View {
        MyListStatisticsCardContainer(
            title: "閱讀總覽",
            subtitle: "\(viewModel.presentation.summary.totalCount) 筆漫畫收藏"
        ) {
            HStack(spacing: 8) {
                MyListProgressSummaryChipView(
                    title: "閱讀中",
                    count: viewModel.presentation.summary.readingCount,
                    systemImageName: MangaReadingStatus.reading.systemImageName
                )
                MyListProgressSummaryChipView(
                    title: "想讀",
                    count: viewModel.presentation.summary.plannedCount,
                    systemImageName: MangaReadingStatus.planned.systemImageName
                )
                MyListProgressSummaryChipView(
                    title: "已完成",
                    count: viewModel.presentation.summary.completedCount,
                    systemImageName: MangaReadingStatus.completed.systemImageName
                )
            }
        }
    }

    private var filterView: some View {
        CapsuleFilterBarView(
            tags: MangaReadingStatusFilter.allCases,
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
                    title: "沒有符合的漫畫",
                    message: "切換閱讀狀態查看其他收藏。"
                )
            )
        } else {
            LazyVStack(spacing: Layout.rowSpacing) {
                ForEach(
                    viewModel.presentation.filteredItems,
                    id: \.persistentModelID
                ) { item in
                    NavigationLink {
                        MangaDetailView(malId: item.malId)
                    } label: {
                        MyListItemRowView(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Private Methods

    private func filterTitle(for filter: MangaReadingStatusFilter) -> String {
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
