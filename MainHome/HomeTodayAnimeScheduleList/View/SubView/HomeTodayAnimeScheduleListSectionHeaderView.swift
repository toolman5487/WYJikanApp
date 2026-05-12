//
//  HomeTodayAnimeScheduleListSectionHeaderView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/5.
//

import SwiftUI

struct HomeTodayAnimeScheduleListSectionHeaderView: View {
    let section: HomeTodayAnimeTimeSection

    var body: some View {
        GlassSectionHeaderView(
            title: section.title,
            state: .accessoryText("\(section.items.count) 部")
        )
        .background(Color(.systemBackground).opacity(0.001))
    }
}
