//
//  HomeTodayAnimeScheduleListDayFilterView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/5.
//

import SwiftUI

// MARK: - HomeTodayAnimeScheduleListDayFilterView

struct HomeTodayAnimeScheduleListDayFilterView: View {

    // MARK: - Properties

    let selectedDay: HomeScheduleDay
    let onSelectDay: (HomeScheduleDay) -> Void

    // MARK: - Body

    var body: some View {
        CapsuleFilterBarView(
            tags: HomeScheduleDay.allCases,
            title: { $0.title },
            selection: selectedDayBinding,
            selectionAnimation: nil
        )
    }

    // MARK: - Private Methods

    private var selectedDayBinding: Binding<HomeScheduleDay> {
        Binding(
            get: { selectedDay },
            set: { newValue in
                onSelectDay(newValue)
            }
        )
    }
}
