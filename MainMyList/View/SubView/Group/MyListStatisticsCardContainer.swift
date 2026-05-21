//
//  MyListStatisticsCardContainer.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/21.
//

import SwiftUI

struct MyListStatisticsCardContainer<Content: View>: View {
    // MARK: - Properties

    let title: String
    let subtitle: String?
    @ViewBuilder let content: Content

    // MARK: - Init

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(ThemeColor.textPrimary)

                if let subtitle, subtitle.isEmpty == false {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(ThemeColor.textSecondary)
                }
            }

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
