//
//  MangaCategoryDetailGridCardView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/2.
//

import SwiftUI

struct MangaCategoryDetailGridCardView: View {

    // MARK: - Properties

    let item: MangaCategoryItemDTO

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            PosterCardView(rank: item.rank) {
                Group {
                    if let posterURL = item.posterURL {
                        RemotePosterImageView(url: posterURL)
                    } else {
                        Color(.secondarySystemFill)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
            }
            .aspectRatio(2.0 / 3.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(item.displayTitle)
                .font(.headline)
                .foregroundStyle(ThemeColor.textPrimary)
                .lineLimit(1)

            Text(metaText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(ThemeColor.textSecondary)

            if let synopsis = item.synopsisPreview {
                Text(synopsis)
                    .font(.caption)
                    .foregroundStyle(ThemeColor.textSecondary)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Private Methods

    private var metaText: String {
        var segments: [String] = []
        if let type = item.type?.trimmingCharacters(in: .whitespacesAndNewlines), !type.isEmpty {
            segments.append(type)
        }
        if let score = item.score {
            segments.append(String(format: "%.1f", score))
        }
        if let chapters = item.chapters {
            segments.append("\(chapters) 話")
        }
        return segments.isEmpty ? "作品資訊" : segments.joined(separator: " ・ ")
    }
}
