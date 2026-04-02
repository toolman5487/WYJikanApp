//
//  AnimeReviewRowMALButton.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

import SwiftUI

struct AnimeReviewRowMALButton: View {

    @Environment(\.openURL) private var openURL

    let url: URL

    var body: some View {
        Button {
            openURL(url)
        } label: {
            Text("在 MyAnimeList 上查看")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(ThemeColor.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .tint(ThemeColor.textPrimary)
        .background(ThemeColor.sakura)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
