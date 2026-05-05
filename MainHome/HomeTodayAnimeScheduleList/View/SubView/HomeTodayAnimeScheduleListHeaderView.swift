//
//  HomeTodayAnimeScheduleListHeaderView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/5.
//

import SwiftUI

struct HomeTodayAnimeScheduleListHeaderView: View {
    let title: String
    let subtitle: String
    let loadedCountText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(ThemeColor.sakura)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(ThemeColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(loadedCountText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(ThemeColor.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.systemBackground).opacity(0.74))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(headerBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var headerBackground: some View {
        LinearGradient(
            colors: [
                ThemeColor.sakura.opacity(0.22),
                ThemeColor.sakura.opacity(0.08),
                Color(.secondarySystemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
