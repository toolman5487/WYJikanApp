//
//  HomeTodayAnimeScheduleListSectionHeaderView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/5.
//

import SwiftUI

// MARK: - HomeTodayAnimeScheduleListSectionHeaderView

struct HomeTodayAnimeScheduleListSectionHeaderView: View {

    // MARK: - Properties

    let section: HomeTodayAnimeTimeSection

    // MARK: - Body

    var body: some View {
        GlassSectionHeaderView(
            title: section.title,
            state: .accessoryText("\(section.items.count) 部"),
            outerVerticalPadding: 8
        )
        .background(Color(.systemBackground).opacity(0.001))
    }
}
