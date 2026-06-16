//
//  MyListSummaryTile.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import SwiftUI

struct MyListSummaryTile: View {

    // MARK: - Properties

    let title: String
    let value: Int
    let iconName: String
    let detail: String

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("目前顯示")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ThemeColor.textSecondary)

                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(ThemeColor.textPrimary)

                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text("\(value)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(ThemeColor.textPrimary)

                    Text("筆收藏")
                        .font(.subheadline)
                        .foregroundStyle(ThemeColor.textSecondary)
                }

                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(ThemeColor.textSecondary)
            }

            Spacer(minLength: 0)

            Image(systemName: iconName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(ThemeColor.sakura)
                .frame(width: 44, height: 44)
                .background(ThemeColor.sakura.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
