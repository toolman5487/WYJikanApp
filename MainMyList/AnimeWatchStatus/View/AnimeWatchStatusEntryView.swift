//
//  AnimeWatchStatusEntryView.swift
//  WYJikanApp
//

import SwiftUI

struct AnimeWatchStatusEntryView: View {

    // MARK: - Properties

    let title: String
    let summary: AnimeWatchStatusSummary
    let action: () -> Void

    // MARK: - Body

    var body: some View {
        MyListProgressStatusEntryView(
            title: title,
            subtitle: "\(summary.totalCount) 筆動畫收藏",
            iconName: "play.rectangle.fill",
            chips: [
                MyListProgressStatusEntryChip(title: "觀看中", count: summary.watchingCount),
                MyListProgressStatusEntryChip(title: "想看", count: summary.plannedCount),
                MyListProgressStatusEntryChip(title: "已看完", count: summary.completedCount)
            ],
            action: action
        )
    }
}
