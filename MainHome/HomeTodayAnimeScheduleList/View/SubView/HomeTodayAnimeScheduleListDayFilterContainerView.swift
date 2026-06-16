//
//  HomeTodayAnimeScheduleListDayFilterContainerView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/5.
//

import SwiftUI

// MARK: - HomeTodayAnimeScheduleListDayFilterContainerView

struct HomeTodayAnimeScheduleListDayFilterContainerView: View {
    private enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let topPadding: CGFloat = 8
        static let dividerSpacing: CGFloat = 8
    }

    // MARK: - Properties

    let selectedDay: HomeScheduleDay
    let onSelectDay: (HomeScheduleDay) -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: Layout.dividerSpacing) {
            HomeTodayAnimeScheduleListDayFilterView(
                selectedDay: selectedDay,
                onSelectDay: onSelectDay
            )
            .padding(.horizontal, Layout.horizontalPadding)

            Divider()
        }
        .padding(.top, Layout.topPadding)
        .background(.ultraThinMaterial)
    }
}
