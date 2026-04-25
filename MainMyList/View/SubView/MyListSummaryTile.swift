//
//  MyListSummaryTile.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import SwiftUI

struct MyListSummaryTile: View {
    let title: String
    let value: Int
    let iconName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: iconName)
                .font(.headline)
                .foregroundStyle(ThemeColor.sakura)
            Text("\(value)")
                .font(.title3.weight(.bold))
                .foregroundStyle(ThemeColor.textPrimary)
            Text(title)
                .font(.caption)
                .foregroundStyle(ThemeColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
