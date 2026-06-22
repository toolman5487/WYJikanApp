//
//  MyListStatisticsSectionView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/21.
//

import SwiftUI

struct MyListStatisticsSectionView: View {

    // MARK: - Types

    private enum ContentState {
        case empty
        case populated
    }

    // MARK: - Properties

    let presentation: MyListPresentation
    let onSelectGenre: (String) -> Void
    let onSelectFormat: (String) -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            MyListSummaryTile(
                title: presentation.summaryTile.title,
                value: presentation.summaryTile.value,
                iconName: presentation.summaryTile.iconName,
                detail: presentation.summaryTile.detail
            )

            switch contentState {
            case .empty:
                MyListStatisticsCardContainer(
                    title: "收藏總覽"
                ) {
                    FeatureEmptyStateInlineView(
                        emptyState: .emptyCollection(message: "尚無收藏統計"),
                        height: 120
                    )
                }

            case .populated:
                chartContent
            }
        }
    }

    // MARK: - Private Views

    @ViewBuilder
    private var chartContent: some View {
        let platform = UserInterfacePlatform.current

        if platform.prefersSideBySideStatisticsCharts {
            HStack(alignment: .top, spacing: 16) {
                formatChart(platform: platform)
                genreChart(platform: platform)
            }
        } else {
            VStack(alignment: .leading, spacing: 16) {
                genreChart(platform: platform)
                formatChart(platform: platform)
            }
        }
    }

    private func genreChart(platform: UserInterfacePlatform) -> some View {
        MyListGenreDistributionChartCardView(
            statistics: presentation.statistics,
            cardMinHeight: platform.statisticsChartCardMinHeight,
            contentMinHeight: platform.statisticsChartContentMinHeight,
            onSelectGenre: onSelectGenre
        )
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func formatChart(platform: UserInterfacePlatform) -> some View {
        MyListFormatDistributionChartCardView(
            statistics: presentation.statistics,
            cardMinHeight: platform.statisticsChartCardMinHeight,
            contentMinHeight: platform.statisticsChartContentMinHeight,
            onSelectFormat: onSelectFormat
        )
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    // MARK: - Private Methods

    private var contentState: ContentState {
        presentation.filteredItems.isEmpty ? .empty : .populated
    }
}
