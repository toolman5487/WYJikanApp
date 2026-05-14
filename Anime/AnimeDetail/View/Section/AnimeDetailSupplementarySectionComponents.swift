//
//  AnimeDetailSupplementarySectionComponents.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/14.
//

import Foundation
import SwiftUI

struct AnimeDetailLinkedSection<Destination: View, Content: View>: View {
    let title: String
    let actionTitle: String
    private let destination: Destination
    private let content: Content

    init(
        title: String,
        actionTitle: String,
        @ViewBuilder destination: () -> Destination,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.actionTitle = actionTitle
        self.destination = destination()
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(title)
                    .font(.title3)
                    .foregroundStyle(ThemeColor.sakura)

                Spacer(minLength: 0)

                NavigationLink {
                    destination
                } label: {
                    Text(actionTitle)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(ThemeColor.textSecondary)
                }
                .buttonStyle(.plain)
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AnimeDetailCharacterCardView: View {
    let name: String
    let role: String
    let voiceActorSummary: String
    let imageURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            portraitView
                .frame(width: 124, height: 156)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ThemeColor.textPrimary)
                    .lineLimit(2)

                Text(role)
                    .font(.caption)
                    .foregroundStyle(ThemeColor.sakura)
                    .lineLimit(1)

                Text(voiceActorSummary)
                    .font(.caption2)
                    .foregroundStyle(ThemeColor.textSecondary)
                    .lineLimit(2)
            }
            .frame(width: 124, alignment: .leading)
        }
    }

    @ViewBuilder
    private var portraitView: some View {
        if let imageURL {
            RemotePosterImageView(url: imageURL)
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray5))
                .overlay {
                    Image(systemName: "person.fill")
                        .foregroundStyle(ThemeColor.textTertiary)
                }
        }
    }
}

struct AnimeDetailRecommendationCardView: View {
    let title: String
    let summary: String
    let imageURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            posterView
                .frame(width: 138, height: 196)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ThemeColor.textPrimary)
                .lineLimit(2)
                .frame(width: 138, alignment: .leading)

            Text(summary)
                .font(.caption2)
                .foregroundStyle(ThemeColor.textSecondary)
                .lineLimit(3)
                .frame(width: 138, alignment: .leading)
        }
    }

    @ViewBuilder
    private var posterView: some View {
        if let imageURL {
            RemotePosterImageView(url: imageURL)
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray5))
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(ThemeColor.textTertiary)
                }
        }
    }
}

struct AnimeDetailEpisodeRowView: View {
    let episode: AnimeEpisodeDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(episodeNumberText)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ThemeColor.sakura)

                Text(episodeTitle)
                    .font(.headline)
                    .foregroundStyle(ThemeColor.textPrimary)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)
            }

            if !metaLine.isEmpty {
                Text(metaLine)
                    .font(.caption)
                    .foregroundStyle(ThemeColor.textSecondary)
            }

            if !tagTexts.isEmpty {
                HStack(spacing: 8) {
                    ForEach(tagTexts, id: \.self) { tag in
                        Text(tag)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(ThemeColor.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(Capsule())
                    }
                }
            }

            if let synopsis = episode.synopsis?.trimmingCharacters(in: .whitespacesAndNewlines),
               !synopsis.isEmpty {
                Text(synopsis)
                    .font(.caption)
                    .foregroundStyle(ThemeColor.textPrimary.opacity(0.9))
                    .lineLimit(3)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var episodeNumberText: String {
        if let malId = episode.malId {
            return "EP \(malId)"
        }
        return "EP"
    }

    private var episodeTitle: String {
        let candidates = [
            episode.titleJapanese,
            episode.titleRomanji,
            episode.title
        ]
        for candidate in candidates {
            if let candidate = candidate?.trimmingCharacters(in: .whitespacesAndNewlines),
               !candidate.isEmpty {
                return candidate
            }
        }
        return "未命名集數"
    }

    private var metaLine: String {
        episode.aired?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private var tagTexts: [String] {
        var result: [String] = []
        if episode.filler == true {
            result.append("Filler")
        }
        if episode.recap == true {
            result.append("Recap")
        }
        return result
    }
}
