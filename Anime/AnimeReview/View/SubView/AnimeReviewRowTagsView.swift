//
//  AnimeReviewRowTagsView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

import SwiftUI

struct AnimeReviewRowTagsView: View {

    let labels: [String]

    var body: some View {
        if !labels.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(labels.enumerated()), id: \.offset) { _, tag in
                        Text(tag)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(ThemeColor.textPrimary)
                            .lineLimit(1)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .frame(minHeight: 44)
                            .background(ThemeColor.sakura)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}
