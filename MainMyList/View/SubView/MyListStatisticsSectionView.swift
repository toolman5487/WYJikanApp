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

    private enum ChartLayout {
        static let iPhoneCardMinHeight: CGFloat = 280
        static let iPadCardMinHeight: CGFloat = 340
        static let iPhoneContentMinHeight: CGFloat = 208
        static let iPadContentMinHeight: CGFloat = 228
    }

    // MARK: - Properties

    let presentation: MyListPresentation
    let onSelectGenre: (String) -> Void
    let onSelectFormat: (String) -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

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
        if horizontalSizeClass == .regular {
            HStack(alignment: .top, spacing: 16) {
                formatChart
                genreChart
            }
        } else {
            VStack(alignment: .leading, spacing: 16) {
                genreChart
                formatChart
            }
        }
    }

    private var genreChart: some View {
        MyListGenreDistributionChartCardView(
            statistics: presentation.statistics,
            cardMinHeight: chartCardMinHeight,
            contentMinHeight: chartContentMinHeight,
            onSelectGenre: onSelectGenre
        )
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var formatChart: some View {
        MyListFormatDistributionChartCardView(
            statistics: presentation.statistics,
            cardMinHeight: chartCardMinHeight,
            contentMinHeight: chartContentMinHeight,
            onSelectFormat: onSelectFormat
        )
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    // MARK: - Private Methods

    private var contentState: ContentState {
        presentation.filteredItems.isEmpty ? .empty : .populated
    }

    private var chartCardMinHeight: CGFloat? {
        horizontalSizeClass == .regular ? ChartLayout.iPadCardMinHeight : ChartLayout.iPhoneCardMinHeight
    }

    private var chartContentMinHeight: CGFloat {
        horizontalSizeClass == .regular ? ChartLayout.iPadContentMinHeight : ChartLayout.iPhoneContentMinHeight
    }
}
