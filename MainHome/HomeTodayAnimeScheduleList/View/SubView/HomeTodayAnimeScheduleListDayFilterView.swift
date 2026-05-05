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
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(HomeScheduleDay.allCases) { day in
                    Button {
                        onSelectDay(day)
                    } label: {
                        Text(day.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(dayForegroundStyle(day))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(dayBackgroundStyle(isSelected: selectedDay == day))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func dayForegroundStyle(_ day: HomeScheduleDay) -> some ShapeStyle {
        selectedDay == day ? AnyShapeStyle(ThemeColor.textPrimary) : AnyShapeStyle(ThemeColor.textSecondary)
    }

    private func dayBackgroundStyle(isSelected: Bool) -> some ShapeStyle {
        isSelected ? AnyShapeStyle(ThemeColor.sakura) : AnyShapeStyle(Color(.secondarySystemBackground))
    }
}
