//
//  MyListProgressSummaryChipView.swift
//  WYJikanApp
//

import SwiftUI

struct MyListProgressSummaryChipView: View {

    // MARK: - Properties

    let title: String
    let count: Int
    let systemImageName: String

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImageName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ThemeColor.sakura)

            Text("\(count)")
                .font(.title3.weight(.bold))
                .foregroundStyle(ThemeColor.textPrimary)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(ThemeColor.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
