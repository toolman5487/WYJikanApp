//
//  AnimeCategoryDetailGridCardView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/2.
//

import SwiftUI

struct AnimeCategoryDetailGridCardView: View {

    // MARK: - Properties

    let item: AnimeCategoryItemDTO
    let isFavorite: Bool

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            posterView

            VStack(alignment: .leading, spacing: 8) {
                Text(item.displayTitle)
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

                if let synopsis = item.synopsisPreview {
                    Text(synopsis)
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

    // MARK: - Private Methods

    private var posterView: some View {
        Group {
            if let posterURL = item.posterURL {
                RemotePosterImageView(
                    url: posterURL,
                    fixedSize: CGSize(width: 84, height: 120)
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
        .frame(width: 84, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var metadataView: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                metadataChips
            }

            HStack(spacing: 8) {
                if let typeText {
                    chip(typeText)
                }

                if let scoreText {
                    chip("★ \(scoreText)")
                }
            }
        }
    }

    @ViewBuilder
    private var metadataChips: some View {
        if let typeText {
            chip(typeText)
        }
        if let scoreText {
            chip("★ \(scoreText)")
        }
        if let episodeText {
            chip(episodeText)
        }
    }

    private var highlightText: String? {
        if let rank = item.rank {
            return "榜單排名 #\(rank)"
        }
        if let popularity = item.popularity {
            return "人氣排名 #\(popularity)"
        }
        return scoreText.map { "口碑評分 ★ \($0)" }
    }

    private var detailLineText: String? {
        [yearText, membersText, popularityText]
            .compactMap { $0 }
            .first(where: { !$0.isEmpty })
    }

    private var typeText: String? {
        trimmedText(item.type)
    }

    private var scoreText: String? {
        item.score.map { String(format: "%.1f", $0) }
    }

    private var episodeText: String? {
        item.episodes.map { "\($0) 集" }
    }

    private var yearText: String? {
        item.year.map { "\($0) 年" }
    }

    private var membersText: String? {
        item.members.map { "\($0.formatted()) 位會員" }
    }

    private var popularityText: String? {
        item.popularity.map { "人氣 #\($0)" }
    }

    private func trimmedText(_ text: String?) -> String? {
        guard let text else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
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
