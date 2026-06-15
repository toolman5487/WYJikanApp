//
//  HomeTodayAnimeScheduleListDayFilterContainerView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/5.
//

import SwiftUI

// MARK: - HomeTodayAnimeScheduleListDayFilterContainerView

struct HomeTodayAnimeScheduleListDayFilterContainerView: View {

    // MARK: - Properties

    let selectedDay: HomeScheduleDay
    let onSelectDay: (HomeScheduleDay) -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            HomeTodayAnimeScheduleListDayFilterView(
                selectedDay: selectedDay,
                onSelectDay: onSelectDay
            )
            .padding(.horizontal, 16)

            Divider()
        }
        .padding(.top, 8)
        .background(.ultraThinMaterial)
    }
}
