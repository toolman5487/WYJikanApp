//
//  HomeWatchListRowView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/9.
//

import SwiftUI

// MARK: - HomeWatchListRowView

struct HomeWatchListRowView: View {

    // MARK: - Properties

    let item: HomeWatchListItem
    let isFavorite: Bool
    let onTap: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                thumbnailView

                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(ThemeColor.textPrimary)
                        .lineLimit(2)

                    Text(item.subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ThemeColor.sakura)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    metadataView

                    Text(actionText)
                        .font(.caption)
                        .foregroundStyle(ThemeColor.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                if item.contentKind == .episode {
                    MyListCollectionStatusBadgeView(isFavorite: isFavorite)
                }

                Image(systemName: actionSystemImageName)
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(ThemeColor.textSecondary)
                    .padding(.top, 4)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Private Methods

    private var thumbnailView: some View {
        Group {
            if let imageURL = item.imageURL {
                RemotePosterImageView(
                    url: imageURL,
                    contentMode: .fill,
                    fixedSize: thumbnailSize
                )
            } else {
                Color(.secondarySystemFill)
                    .overlay {
                        Image(systemName: item.contentKind == .promo ? "play.rectangle" : "photo")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(width: thumbnailSize.width, height: thumbnailSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var metadataView: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                metadataChips
            }

            HStack(spacing: 8) {
                chip(item.contentKind.title)
                if let firstBadge = item.badgeTexts.first(where: { $0 != item.contentKind.title }) {
                    chip(firstBadge)
                }
            }
        }
    }

    @ViewBuilder
    private var metadataChips: some View {
        chip(item.contentKind.title)
        ForEach(item.badgeTexts.filter { $0 != item.contentKind.title }.prefix(2), id: \.self) { badge in
            chip(badge)
        }
    }

    private var thumbnailSize: CGSize {
        CGSize(width: 84, height: 120)
    }

    private var actionText: String {
        switch (item.contentKind, item.actionURL) {
        case (.episode, .some):
            return "觀看集數"
        case (.episode, .none):
            return "查看動畫詳情"
        case (.promo, .some):
            return "觀看預告"
        case (.promo, .none):
            return "查看動畫詳情"
        }
    }

    private var actionSystemImageName: String {
        switch (item.contentKind, item.actionURL) {
        case (.episode, .some):
            return "play.rectangle.on.rectangle"
        case (.promo, .some):
            return "play.rectangle"
        case (_, .none):
            return "chevron.right"
        }
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(ThemeColor.textPrimary)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(ThemeColor.sakura.opacity(0.55))
            .clipShape(Capsule())
    }
}
