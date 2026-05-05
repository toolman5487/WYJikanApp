//
//  HomeTrendingAnimeListRowView.swift
//  WYJikanApp
//
//  Created by Willy Hsu 2026/5/5.
//

import SwiftUI

struct HomeTrendingAnimeListRowView: View {
    let item: HomeTrendingAnimeListItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                posterView

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        if let rank = item.rank {
                            Text("#\(rank)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(ThemeColor.textPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(ThemeColor.sakura.opacity(0.72))
                                .clipShape(Capsule())
                        }

                        Text(item.title)
                            .font(.headline)
                            .foregroundStyle(ThemeColor.textPrimary)
                            .lineLimit(2)
                    }

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 6) {
                            chips
                        }

                        HStack(spacing: 6) {
                            if let typeText = item.typeText {
                                chip(typeText)
                            }
                            if let scoreText = item.scoreText {
                                chip("★ \(scoreText)")
                            }
                        }
                    }

                    if let seasonText = item.seasonText {
                        Text(seasonText)
                            .font(.caption)
                            .foregroundStyle(ThemeColor.textSecondary)
                            .lineLimit(1)
                    }

                    if let synopsisPreview = item.synopsisPreview {
                        Text(synopsisPreview)
                            .font(.caption)
                            .foregroundStyle(ThemeColor.textSecondary)
                            .lineLimit(3)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(alignment: .topTrailing) {
                MyListCollectionStatusBadgeView(malId: item.id, mediaKind: .anime)
                    .padding(8)
            }
        }
        .buttonStyle(.plain)
    }

    private var posterView: some View {
        Group {
            if let imageURL = item.imageURL {
                RemotePosterImageView(url: imageURL)
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
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private var chips: some View {
        if let typeText = item.typeText {
            chip(typeText)
        }
        if let scoreText = item.scoreText {
            chip("★ \(scoreText)")
        }
        if let popularityText = item.popularityText {
            chip(popularityText)
        }
        if let membersText = item.membersText {
            chip(membersText)
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
