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
                    .frame(height: chartHeight)
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

                    if statistics.selectedAnalysis.missingGenreItemCount > 0 {
                        Text("有 \(statistics.selectedAnalysis.missingGenreItemCount) 筆既有收藏尚未記錄種類，重新收藏後會納入統計。")
                            .font(.footnote)
                            .foregroundStyle(ThemeColor.textSecondary)
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
}
