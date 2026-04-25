//
//  MyListItemRowView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import SwiftUI

struct MyListItemRowView: View {
    let item: MyListCollectionItem

    var body: some View {
        HStack(spacing: 12) {
            posterView
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: item.mediaKind.iconName)
                    Text(item.mediaKind.title)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(ThemeColor.sakura)

                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(ThemeColor.textPrimary)
                    .lineLimit(2)

                if let subtitle = item.subtitle, !subtitle.isEmpty, subtitle != item.title {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(ThemeColor.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(ThemeColor.textTertiary)
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private var posterView: some View {
        if let url = item.imageURL {
            RemotePosterImageView(url: url)
                .frame(width: 58, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.tertiarySystemBackground))
                .frame(width: 58, height: 84)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(ThemeColor.textTertiary)
                }
        }
    }
}
