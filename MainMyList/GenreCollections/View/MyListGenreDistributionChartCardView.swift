//
//  MyListGenreDistributionChartCardView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/21.
//

import SwiftUI

struct MyListGenreDistributionChartCardView: View {
    private enum Layout {
        static let legendMarkerSize: CGFloat = 24
        static let legendDotSize: CGFloat = 8
    }

    // MARK: - Properties

    let statistics: MyListStatistics
    let cardMinHeight: CGFloat?
    let contentMinHeight: CGFloat
    let onSelectGenre: (String) -> Void

    // MARK: - Body

    var body: some View {
        cardContent
    }

    // MARK: - Private Views

    private var cardContent: some View {
        MyListStatisticsCardContainer(
            title: "\(statistics.selectedAnalysis.scope.title)收藏種類比例",
            subtitle: distributionSubtitle,
            minHeight: cardMinHeight
        ) {
            if statistics.selectedAnalysis.genreSlices.isEmpty {
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
            if let topGenreSlice = statistics.selectedAnalysis.topGenreSlice {
                Text("\(localizedGenreName(topGenreSlice.genreName)) 佔 \(percentageText(for: topGenreSlice))，是目前收藏中最明顯的種類。")
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

    private var chartView: some View {
        Button {
            selectDefaultGenre()
        } label: {
            MyListPieChartView(
                slices: pieChartSlices,
                totalCount: statistics.selectedAnalysis.itemCount,
                categoryLabel: "種類",
                colors: chartColors
            )
        }
        .buttonStyle(.plain)
    }

    private var legendView: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(statistics.selectedAnalysis.genreSlices.enumerated()), id: \.element.id) { index, slice in
                Button {
                    onSelectGenre(slice.genreName)
                } label: {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(color(for: index).opacity(0.18))
                                .frame(width: Layout.legendMarkerSize, height: Layout.legendMarkerSize)

                            Circle()
                                .fill(color(for: index))
                                .frame(width: Layout.legendDotSize, height: Layout.legendDotSize)
                        }

                        Text(localizedGenreName(slice.genreName))
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
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Private Methods

    private var distributionSubtitle: String? {
        guard let topGenreSlice = statistics.selectedAnalysis.topGenreSlice else {
            if statistics.selectedAnalysis.missingGenreItemCount > 0 {
                return "尚無可用種類資料"
            }

            return nil
        }

        var subtitle = "\(localizedGenreName(topGenreSlice.genreName)) 最多，\(topGenreSlice.count) 筆"
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

    private var pieChartSlices: [MyListPieChartSlice] {
        statistics.selectedAnalysis.genreSlices.map { slice in
            MyListPieChartSlice(
                id: slice.id,
                title: localizedGenreName(slice.genreName),
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

    private func localizedGenreName(_ genreName: String) -> String {
        AnimeGenreLocalizationModel.localizedName(for: genreName)
    }

    private func selectDefaultGenre() {
        guard let topGenreSlice = statistics.selectedAnalysis.topGenreSlice else { return }
        onSelectGenre(topGenreSlice.genreName)
    }

    private func percentageText(
        for slice: MyListGenreSlice
    ) -> String {
        guard statistics.selectedAnalysis.itemCount > 0 else { return "0%" }
        let percentage = Double(slice.count) / Double(statistics.selectedAnalysis.itemCount)
        return percentage.formatted(.percent.precision(.fractionLength(0)))
    }
}
