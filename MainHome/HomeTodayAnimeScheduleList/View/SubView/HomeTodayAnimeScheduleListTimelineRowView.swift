//
//  HomeTodayAnimeScheduleListTimelineRowView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/5.
//

import SwiftUI

struct HomeTodayAnimeScheduleListTimelineRowView: View {
    let item: HomeTodayAnimeTimelineItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                posterView

                VStack(alignment: .leading, spacing: 7) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(ThemeColor.textPrimary)
                        .lineLimit(2)

                    Text(item.broadcastText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ThemeColor.sakura)
                        .lineLimit(1)

                    metadataView

                    if let studio = item.studioText {
                        Text(studio)
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
            .padding(10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
        .frame(width: 76, height: 112)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var metadataView: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) {
                metadataChips
            }

            HStack(spacing: 6) {
                if let type = item.typeText {
                    metadataChip(type)
                }
                if let score = item.scoreText {
                    metadataChip("★ \(score)")
                }
            }
        }
    }

    @ViewBuilder
    private var metadataChips: some View {
        if let type = item.typeText {
            metadataChip(type)
        }
        if let score = item.scoreText {
            metadataChip("★ \(score)")
        }
        if let episode = item.episodeText {
            metadataChip(episode)
        }
        if let status = item.statusText {
            metadataChip(status)
        }
    }

    private func metadataChip(_ text: String) -> some View {
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
