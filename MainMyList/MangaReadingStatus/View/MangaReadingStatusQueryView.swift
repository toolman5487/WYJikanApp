//
//  MangaReadingStatusQueryView.swift
//  WYJikanApp
//

import SwiftData
import SwiftUI

struct MangaReadingStatusQueryView: View {

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
                summaryChip(
                    title: "閱讀中",
                    count: viewModel.presentation.summary.readingCount,
                    systemImageName: MangaReadingStatus.reading.systemImageName
                )
                summaryChip(
                    title: "想讀",
                    count: viewModel.presentation.summary.plannedCount,
                    systemImageName: MangaReadingStatus.planned.systemImageName
                )
                summaryChip(
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
            LazyVStack(spacing: 12) {
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

    private func summaryChip(
        title: String,
        count: Int,
        systemImageName: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImageName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ThemeColor.sakura)

            Text("\(count)")
                .font(.title3.weight(.bold))
                .foregroundStyle(ThemeColor.textPrimary)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(ThemeColor.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
