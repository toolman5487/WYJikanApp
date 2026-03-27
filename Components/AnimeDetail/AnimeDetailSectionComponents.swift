//
//  AnimeDetailSectionComponents.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import SwiftUI

struct AnimeDetailSectionCard<Content: View>: View {
    let title: String
    private let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3)
                .foregroundStyle(ThemeColor.sakura)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AnimeDetailInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ThemeColor.textSecondary)
                .frame(width: 72, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .foregroundStyle(ThemeColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
