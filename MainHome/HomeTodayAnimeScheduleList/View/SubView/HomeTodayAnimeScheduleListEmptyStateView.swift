//
//  HomeTodayAnimeScheduleListEmptyStateView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/5.
//

import SwiftUI

struct HomeTodayAnimeScheduleListEmptyStateView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("這天目前沒有可顯示的 TV 動畫")
                .font(.title3.weight(.bold))
                .foregroundStyle(ThemeColor.textPrimary)

            Text("可以切換其他星期，或稍後再回來看看。")
                .font(.body)
                .foregroundStyle(ThemeColor.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .center)
        .padding(24)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
