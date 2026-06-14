//
//  MangaReadingStatusEntryView.swift
//  WYJikanApp
//

import SwiftUI

struct MangaReadingStatusEntryView: View {

    // MARK: - Properties

    let title: String
    let summary: MangaReadingStatusSummary
    let action: () -> Void

    // MARK: - Body

    var body: some View {
        MyListProgressStatusEntryView(
            title: title,
            subtitle: "\(summary.totalCount) 筆漫畫收藏",
            iconName: "books.vertical.fill",
            chips: [
                MyListProgressStatusEntryChip(title: "閱讀中", count: summary.readingCount),
                MyListProgressStatusEntryChip(title: "想讀", count: summary.plannedCount),
                MyListProgressStatusEntryChip(title: "已完成", count: summary.completedCount)
            ],
            action: action
        )
    }
}
