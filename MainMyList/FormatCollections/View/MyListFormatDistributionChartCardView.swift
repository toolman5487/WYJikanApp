//
//  MyListFormatDistributionChartCardView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/21.
//

import SwiftUI

struct MyListFormatDistributionChartCardView: View {
    private enum Layout {
        static let legendMarkerSize: CGFloat = 24
    }

    // MARK: - Properties

    let statistics: MyListStatistics
    let cardMinHeight: CGFloat?
    let contentMinHeight: CGFloat
    let onSelectFormat: (String) -> Void

    // MARK: - Body

    @ViewBuilder
    var body: some View {
        if statistics.formatAnalysis.formatSlices.isEmpty {
            cardContent
        } else {
            Button {
                selectDefaultFormat()
            } label: {
                cardContent
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Private Views

    private var cardContent: some View {
        MyListStatisticsCardContainer(
            title: "\(statistics.formatAnalysis.scope.title)收藏形式比例",
            subtitle: distributionSubtitle,
            minHeight: cardMinHeight
        ) {
            if statistics.formatAnalysis.formatSlices.isEmpty {
                FeatureEmptyStateInlineView(
                    emptyState: .emptyCollection(message: emptyStateMessage),
                    height: 120
                )
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    chartLegendView

                    Spacer(minLength: 0)

                    footerTextView
                }
                .frame(maxWidth: .infinity, minHeight: contentMinHeight, alignment: .topLeading)
            }
        }
    }

    // MARK: - Private Views

    private var chartLegendView: some View {
        HStack(alignment: .center, spacing: 20) {
            chartView

            legendView
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var footerTextView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let topFormatSlice = statistics.formatAnalysis.topFormatSlice {
                Text("\(topFormatSlice.title) 佔 \(percentageText(for: topFormatSlice))，是目前收藏中最主要的作品形式。")
                    .font(.footnote)
                    .foregroundStyle(ThemeColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if statistics.formatAnalysis.missingTypeItemCount > 0 {
                Text("有 \(statistics.formatAnalysis.missingTypeItemCount) 筆舊收藏尚未記錄作品形式，重新收藏後會納入統計。")
                    .font(.footnote)
                    .foregroundStyle(ThemeColor.textSecondary)
            }
        }
    }

    private var chartView: some View {
        MyListPieChartView(
            slices: pieChartSlices,
            totalCount: statistics.formatAnalysis.itemCount,
            categoryLabel: "作品形式",
            colors: chartColors
        )
    }

    private var legendView: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(statistics.formatAnalysis.formatSlices.enumerated()), id: \.element.id) { index, slice in
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(color(for: index).opacity(0.18))
                            .frame(width: Layout.legendMarkerSize, height: Layout.legendMarkerSize)

                        Image(systemName: slice.iconName)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(color(for: index))
                    }

                    Text(slice.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ThemeColor.textPrimary)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Text(percentageText(for: slice))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(ThemeColor.textSecondary)
                        .lineLimit(1)
                }
                .frame(minHeight: Layout.legendMarkerSize)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Private Methods

    private var distributionSubtitle: String? {
        guard let topFormatSlice = statistics.formatAnalysis.topFormatSlice else {
            if statistics.formatAnalysis.missingTypeItemCount > 0 {
                return "尚無可用形式資料"
            }

            return nil
        }

        var subtitle = "\(topFormatSlice.title) 最多，\(topFormatSlice.count) 筆"
        if statistics.formatAnalysis.missingTypeItemCount > 0 {
            subtitle += " ・\(statistics.formatAnalysis.missingTypeItemCount) 筆未記錄形式"
        }
        return subtitle
    }

    private var emptyStateMessage: String {
        if statistics.formatAnalysis.missingTypeItemCount > 0 {
            return "尚無可用形式資料"
        }

        return "尚無作品形式資料"
    }

    private var pieChartSlices: [MyListPieChartSlice] {
        statistics.formatAnalysis.formatSlices.map { slice in
            MyListPieChartSlice(
                id: slice.id,
                title: slice.title,
                count: slice.count
            )
        }
    }

    private func color(for index: Int) -> Color {
        chartColors[index % chartColors.count]
    }

    private var chartColors: [Color] {
        [
            .red,
            .orange,
            .yellow,
            .green,
            .blue,
            .indigo,
            .purple
        ]
    }

    private func selectDefaultFormat() {
        guard let topFormatSlice = statistics.formatAnalysis.topFormatSlice else { return }
        onSelectFormat(topFormatSlice.title)
    }

    private func percentageText(
        for slice: MyListFormatSlice
    ) -> String {
        guard statistics.formatAnalysis.itemCount > 0 else { return "0%" }
        let percentage = Double(slice.count) / Double(statistics.formatAnalysis.itemCount)
        return percentage.formatted(.percent.precision(.fractionLength(0)))
    }
}
