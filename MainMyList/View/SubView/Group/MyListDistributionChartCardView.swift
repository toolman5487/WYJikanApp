//
//  MyListDistributionChartCardView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/21.
//

import Charts
import SwiftUI

struct MyListDistributionChartCardView: View {
    // MARK: - Properties

    let statistics: MainMyListViewModel.Presentation.Statistics

    // MARK: - Body

    var body: some View {
        MyListStatisticsCardContainer(
            title: "\(statistics.selectedAnalysis.scope.title)收藏種類分布",
            subtitle: distributionSubtitle
        ) {
            if statistics.selectedAnalysis.genreSlices.isEmpty {
                ErrorMessageView(
                    state: .emptyCollection(emptyStateMessage),
                    height: 120
                )
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    chartView
                        .frame(height: chartHeight)

                    if let topGenreSlice = statistics.selectedAnalysis.topGenreSlice {
                        Text("\(topGenreSlice.genreName) 佔 \(percentageText(for: topGenreSlice))，是目前收藏中最明顯的種類。")
                            .font(.footnote)
                            .foregroundStyle(ThemeColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if statistics.selectedAnalysis.missingGenreItemCount > 0 {
                        Text("有 \(statistics.selectedAnalysis.missingGenreItemCount) 筆既有收藏尚未記錄種類，重新收藏後會納入統計。")
                            .font(.footnote)
                            .foregroundStyle(ThemeColor.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Private Views

    private var chartView: some View {
        Chart(statistics.selectedAnalysis.genreSlices) { slice in
            BarMark(
                x: .value("收藏數量", slice.count),
                y: .value("種類", slice.genreName)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        ThemeColor.sakura.opacity(0.9),
                        ThemeColor.sakura.opacity(0.45)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .annotation(position: .trailing, alignment: .leading) {
                Text("\(slice.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ThemeColor.textSecondary)
            }
        }
        .chartXAxis {
            AxisMarks(position: .bottom) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [2, 4]))
                    .foregroundStyle(Color(.systemGray4))
                AxisValueLabel {
                    if let count = value.as(Int.self) {
                        Text("\(count)")
                            .font(.caption2)
                            .foregroundStyle(ThemeColor.textSecondary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine().foregroundStyle(.clear)
                AxisTick().foregroundStyle(.clear)
                AxisValueLabel {
                    if let genreName = value.as(String.self) {
                        Text(genreName)
                            .font(.caption)
                            .foregroundStyle(ThemeColor.textPrimary)
                    }
                }
            }
        }
    }

    // MARK: - Private Methods

    private var distributionSubtitle: String? {
        guard let topGenreSlice = statistics.selectedAnalysis.topGenreSlice else {
            if statistics.selectedAnalysis.missingGenreItemCount > 0 {
                return "尚無可用種類資料"
            }

            return nil
        }

        var subtitle = "\(topGenreSlice.genreName) 最多，\(topGenreSlice.count) 筆"
        if statistics.selectedAnalysis.missingGenreItemCount > 0 {
            subtitle += " ・\(statistics.selectedAnalysis.missingGenreItemCount) 筆未分類"
        }
        return subtitle
    }

    private var emptyStateMessage: String {
        if statistics.selectedAnalysis.missingGenreItemCount > 0 {
            return "尚無可用種類資料"
        }

        return "尚無種類資料"
    }

    private var chartHeight: CGFloat {
        let rowCount = max(statistics.selectedAnalysis.genreSlices.count, 1)
        return CGFloat(rowCount) * 32 + 32
    }

    private func percentageText(
        for slice: MainMyListViewModel.Presentation.Statistics.GenreSlice
    ) -> String {
        guard statistics.selectedAnalysis.itemCount > 0 else { return "0%" }
        let percentage = Double(slice.count) / Double(statistics.selectedAnalysis.itemCount)
        return percentage.formatted(.percent.precision(.fractionLength(0)))
    }
}

struct MyListFormatDistributionChartCardView: View {
    // MARK: - Properties

    let statistics: MainMyListViewModel.Presentation.Statistics

    // MARK: - Body

    var body: some View {
        MyListStatisticsCardContainer(
            title: "\(statistics.formatAnalysis.scope.title)收藏形式比例",
            subtitle: distributionSubtitle
        ) {
            if statistics.formatAnalysis.formatSlices.isEmpty {
                ErrorMessageView(
                    state: .emptyCollection(emptyStateMessage),
                    height: 120
                )
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .center, spacing: 20) {
                        chartView
                            .frame(width: 164, height: 164)

                        legendView
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

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
        }
    }

    // MARK: - Private Views

    private var chartView: some View {
        Chart(statistics.formatAnalysis.formatSlices) { slice in
            SectorMark(
                angle: .value("收藏數量", slice.count),
                innerRadius: .ratio(0.58),
                angularInset: 2
            )
            .cornerRadius(4)
            .foregroundStyle(by: .value("作品形式", slice.title))
        }
        .chartLegend(.hidden)
        .chartForegroundStyleScale(
            domain: statistics.formatAnalysis.formatSlices.map(\.title),
            range: chartColors
        )
        .chartBackground { _ in
            VStack(spacing: 2) {
                Text("\(statistics.formatAnalysis.itemCount)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(ThemeColor.textPrimary)

                Text("收藏")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(ThemeColor.textSecondary)
            }
        }
    }

    private var legendView: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(statistics.formatAnalysis.formatSlices.enumerated()), id: \.element.id) { index, slice in
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(color(for: index).opacity(0.18))
                            .frame(width: 24, height: 24)

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

    private func percentageText(
        for slice: MainMyListViewModel.Presentation.Statistics.FormatSlice
    ) -> String {
        guard statistics.formatAnalysis.itemCount > 0 else { return "0%" }
        let percentage = Double(slice.count) / Double(statistics.formatAnalysis.itemCount)
        return percentage.formatted(.percent.precision(.fractionLength(0)))
    }
}
