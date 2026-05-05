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
        HStack {
            Text(section.title)
                .font(.headline.weight(.bold))
                .foregroundStyle(ThemeColor.sakura)

            Text("\(section.items.count) 部")
                .font(.caption.weight(.semibold))
                .foregroundStyle(ThemeColor.textSecondary)

            Spacer()
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}
