//
//  HomeTrendingAnimeListRowView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/5/5.
//

import SwiftUI

struct HomeTrendingAnimeListRowView: View {

    // MARK: - Properties

    let item: HomeTrendingAnimeListItem
    let sort: HomeTrendingAnimeListSort
    let isFavorite: Bool
    let onTap: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                posterView

                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(ThemeColor.textPrimary)
                        .lineLimit(2)

                    if let highlightText {
                        Text(highlightText)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(ThemeColor.sakura)
                            .lineLimit(1)
                    }

                    metadataView

                    if let detailLineText {
                        Text(detailLineText)
                            .font(.caption)
                            .foregroundStyle(ThemeColor.textSecondary)
                            .lineLimit(1)
                    }

                    if let synopsisPreview = item.synopsisPreview {
                        Text(synopsisPreview)
                            .font(.caption)
                            .foregroundStyle(ThemeColor.textSecondary)
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(alignment: .topTrailing) {
                MyListCollectionStatusBadgeView(isFavorite: isFavorite)
                    .padding(8)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Private Methods

    private var posterView: some View {
        Group {
            if let imageURL = item.imageURL {
                RemotePosterImageView(
                    url: imageURL,
                    fixedSize: CGSize(width: 82, height: 120)
                )
            } else {
                Color(.secondarySystemFill)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(width: 82, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var metadataView: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                metadataChips
            }

            HStack(spacing: 8) {
                if let typeText = item.typeText {
                    chip(typeText)
                }
                if let scoreText = item.scoreText {
                    chip("★ \(scoreText)")
                }
            }
        }
    }

    @ViewBuilder
    private var metadataChips: some View {
        if let typeText = item.typeText {
            chip(typeText)
        }
        if let scoreText = item.scoreText {
            chip("★ \(scoreText)")
        }
        if let episodeText = item.episodeText {
            chip(episodeText)
        }
        if let statusText = item.statusText {
            chip(statusText)
        }
    }

    private var highlightText: String? {
        switch sort {
        case .apiDefault, .rank:
            return item.rank.map { "榜單排名 #\($0)" }
        case .popularity:
            return item.popularityText
        case .score:
            return item.scoreText.map { "口碑評分 ★ \($0)" }
        }
    }

    private var detailLineText: String? {
        [item.seasonText, item.membersText, secondaryMetricText]
            .compactMap { $0 }
            .first(where: { !$0.isEmpty })
    }

    private var secondaryMetricText: String? {
        switch sort {
        case .apiDefault, .rank:
            return item.popularityText
        case .popularity:
            return item.scoreText.map { "評分 \($0)" }
        case .score:
            return item.popularityText
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
