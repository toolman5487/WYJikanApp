//
//  HomeTodayAnimeScheduleListDayFilterContainerView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/5.
//

import SwiftUI

struct HomeTodayAnimeScheduleListDayFilterContainerView: View {
    let selectedDay: HomeScheduleDay
    let onSelectDay: (HomeScheduleDay) -> Void

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
