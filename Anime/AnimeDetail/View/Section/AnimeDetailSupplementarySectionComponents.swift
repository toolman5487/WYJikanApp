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
        VStack(alignment: .leading, spacing: 12) {
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
        VStack(alignment: .leading, spacing: 12) {
            posterView
                .frame(width: 136, height: 196)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ThemeColor.textPrimary)
                .lineLimit(2)
                .frame(width: 136, alignment: .leading)

            Text(summary)
                .font(.caption2)
                .foregroundStyle(ThemeColor.textSecondary)
                .lineLimit(3)
                .frame(width: 136, alignment: .leading)
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
