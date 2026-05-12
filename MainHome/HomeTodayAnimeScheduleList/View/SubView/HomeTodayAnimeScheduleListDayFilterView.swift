//
//  HomeTodayAnimeScheduleListDayFilterView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/5.
//

import SwiftUI

struct HomeTodayAnimeScheduleListDayFilterView: View {
    let selectedDay: HomeScheduleDay
    let onSelectDay: (HomeScheduleDay) -> Void

    var body: some View {
        CapsuleFilterBarView(
            tags: HomeScheduleDay.allCases,
            title: { $0.title },
            selection: selectedDayBinding
        )
    }

    private var selectedDayBinding: Binding<HomeScheduleDay> {
        Binding(
            get: { selectedDay },
            set: { newValue in
                onSelectDay(newValue)
            }
        )
    }
}
