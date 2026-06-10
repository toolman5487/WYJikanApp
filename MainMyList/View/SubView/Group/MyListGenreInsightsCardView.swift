//
//  MyListGenreInsightsCardView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/21.
//

import SwiftUI

struct MyListGenreInsightsCardView: View {
    // MARK: - Properties

    let statistics: MyListStatistics

    // MARK: - Body

    var body: some View {
        MyListStatisticsCardContainer(
            title: "收藏偏好整理",
            subtitle: nil
        ) {
            VStack(alignment: .leading, spacing: 12) {
                insightRow(for: statistics.selectedAnalysis)
            }
        }
    }

    // MARK: - Private Views

    private func insightRow(
        for analysis: MyListGenreAnalysis
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(analysis.scope.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ThemeColor.textPrimary)

                Text("\(analysis.itemCount) 筆收藏")
                    .font(.caption)
                    .foregroundStyle(ThemeColor.textSecondary)
            }

            if let description = insightDescription(for: analysis) {
                Text(description)
                    .font(.footnote)
                    .foregroundStyle(ThemeColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                emptyInsightIcon
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.systemBackground).opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var emptyInsightIcon: some View {
        ZStack {
            Circle()
                .fill(ThemeColor.textTertiary.opacity(0.14))
                .frame(width: 40, height: 40)

            Image(systemName: "tray.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(ThemeColor.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .accessibilityHidden(true)
    }

    // MARK: - Private Methods

    private func insightDescription(
        for analysis: MyListGenreAnalysis
    ) -> String? {
        guard analysis.itemCount > 0,
              let topGenreSlice = analysis.topGenreSlice else {
            return nil
        }

        var text = "最常收藏的是 \(topGenreSlice.genreName)，共 \(topGenreSlice.count) 筆。"
        if let secondGenreSlice = analysis.genreSlices.dropFirst().first {
            text += " 接著是 \(secondGenreSlice.genreName) \(secondGenreSlice.count) 筆。"
        }
        if analysis.missingGenreItemCount > 0 {
            text += " 另有 \(analysis.missingGenreItemCount) 筆舊收藏尚未記錄種類。"
        }
        return text
    }
}
