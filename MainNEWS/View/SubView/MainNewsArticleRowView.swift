//
//  MainNewsArticleRowView.swift
//  WYJikanApp
//

import SwiftUI

struct MainNewsArticleRowView: View {
    let row: MainNewsRow
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                thumbnailView

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(row.sourceName)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(ThemeColor.sakura)
                            .lineLimit(1)

                        if let publishedText = row.publishedText {
                            Text(publishedText)
                                .font(.caption)
                                .foregroundStyle(ThemeColor.textSecondary)
                                .lineLimit(1)
                        }
                    }

                    Text(row.title)
                        .font(.headline)
                        .foregroundStyle(ThemeColor.textPrimary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    if let summary = row.summary {
                        Text(summary)
                            .font(.subheadline)
                            .foregroundStyle(ThemeColor.textSecondary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    metadataView
                }

                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ThemeColor.textSecondary)
                    .frame(width: 24, height: 24)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var thumbnailView: some View {
        Group {
            if let imageURL = row.imageURL {
                RemotePosterImageView(
                    url: imageURL,
                    contentMode: .fill,
                    fixedSize: CGSize(width: 96, height: 72)
                )
            } else {
                Color(.tertiarySystemFill)
                    .overlay {
                        Image(systemName: "newspaper")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(ThemeColor.textSecondary)
                    }
            }
        }
        .frame(width: 96, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private var metadataView: some View {
        let metadata = [row.categoryText, row.authorText]
            .compactMap { $0 }
            .filter { !$0.isEmpty }

        if !metadata.isEmpty {
            Text(metadata.joined(separator: " · "))
                .font(.caption)
                .foregroundStyle(ThemeColor.textSecondary)
                .lineLimit(1)
        }
    }
}
