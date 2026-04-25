//
//  MyListEmptyStateView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import SwiftUI

struct MyListEmptyStateView: View {
    let title: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(ThemeColor.sakura)
            Text(title)
                .font(.headline)
                .foregroundStyle(ThemeColor.textPrimary)
            Text("在作品詳情頁點右上角的愛心，就會加入收藏。")
                .font(.subheadline)
                .foregroundStyle(ThemeColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
        .padding(.horizontal, 20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
