//
//  MyListPieChartView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/15.
//

import Charts
import SwiftUI

// MARK: - MyListPieChartSlice

struct MyListPieChartSlice: Identifiable, Hashable {
    let id: String
    let title: String
    let count: Int
}

// MARK: - MyListPieChartView

struct MyListPieChartView: View {

    // MARK: - Constants

    private static let chartSize: CGFloat = 148

    // MARK: - Properties

    let slices: [MyListPieChartSlice]
    let totalCount: Int
    let categoryLabel: String
    let colors: [Color]

    // MARK: - Body

    var body: some View {
        Chart(slices) { slice in
            SectorMark(
                angle: .value("收藏數量", slice.count),
                innerRadius: .ratio(0.58),
                angularInset: 2
            )
            .cornerRadius(4)
            .foregroundStyle(by: .value(categoryLabel, slice.title))
        }
        .chartLegend(.hidden)
        .chartForegroundStyleScale(
            domain: slices.map(\.title),
            range: colors
        )
        .chartBackground { _ in
            VStack(spacing: 2) {
                Text("\(totalCount)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(ThemeColor.textPrimary)

                Text("收藏")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(ThemeColor.textSecondary)
            }
        }
        .frame(width: Self.chartSize, height: Self.chartSize)
        .fixedSize()
        .layoutPriority(1)
    }
}
