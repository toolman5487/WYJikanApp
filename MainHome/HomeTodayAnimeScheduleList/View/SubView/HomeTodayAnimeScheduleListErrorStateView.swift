//
//  HomeTodayAnimeScheduleListErrorStateView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/5.
//

import SwiftUI

struct HomeTodayAnimeScheduleListErrorStateView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("播出表暫時讀不到")
                .font(.title3.weight(.bold))
                .foregroundStyle(ThemeColor.textPrimary)

            Text(message)
                .font(.body)
                .foregroundStyle(ThemeColor.textSecondary)

            Button("重新載入", action: onRetry)
                .buttonStyle(.borderedProminent)
                .tint(ThemeColor.sakura)
        }
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .center)
        .padding(24)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
