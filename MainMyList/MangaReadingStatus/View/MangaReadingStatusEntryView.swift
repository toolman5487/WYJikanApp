//
//  MangaReadingStatusEntryView.swift
//  WYJikanApp
//

import SwiftUI

struct MangaReadingStatusEntryView: View {

    // MARK: - Properties

    let summary: MangaReadingStatusSummary
    let action: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 16) {
                iconView

                VStack(alignment: .leading, spacing: 10) {
                    titleView
                    statusSummaryView
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ThemeColor.textTertiary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("漫畫閱讀狀態")
    }

    // MARK: - Private Views

    private var iconView: some View {
        Image(systemName: "books.vertical.fill")
            .font(.title3.weight(.semibold))
            .foregroundStyle(ThemeColor.sakura)
            .frame(width: 44, height: 44)
            .background(ThemeColor.sakura.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var titleView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("漫畫閱讀狀態")
                .font(.headline)
                .foregroundStyle(ThemeColor.textPrimary)

            Text("\(summary.totalCount) 筆漫畫收藏")
                .font(.footnote)
                .foregroundStyle(ThemeColor.textSecondary)
        }
    }

    private var statusSummaryView: some View {
        HStack(spacing: 8) {
            summaryChip(title: "閱讀中", count: summary.readingCount)
            summaryChip(title: "想讀", count: summary.plannedCount)
            summaryChip(title: "已完成", count: summary.completedCount)
        }
    }

    private func summaryChip(title: String, count: Int) -> some View {
        Text("\(title) \(count)")
            .font(.caption.weight(.semibold))
            .foregroundStyle(ThemeColor.textSecondary)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.tertiarySystemBackground))
            .clipShape(Capsule())
    }
}
