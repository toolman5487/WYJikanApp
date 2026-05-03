//
//  MangaCategoryDetailHeaderView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/2.
//

import SwiftUI

struct MangaCategoryDetailHeaderView: View {
    let title: String
    let subtitle: String
    let loadedCountText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(ThemeColor.sakura)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(ThemeColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                headerPill(title: "分類探索")
                headerPill(title: "重新篩選")
                headerPill(title: loadedCountText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(headerBackground)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var headerBackground: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [
                    ThemeColor.sakura.opacity(0.22),
                    ThemeColor.sakura.opacity(0.08),
                    Color(.secondarySystemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(ThemeColor.sakura.opacity(0.12))
                .frame(width: 120, height: 120)
                .offset(x: 24, y: -34)
        }
    }

    private func headerPill(title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(ThemeColor.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.systemBackground).opacity(0.72))
            .clipShape(Capsule())
    }
}
