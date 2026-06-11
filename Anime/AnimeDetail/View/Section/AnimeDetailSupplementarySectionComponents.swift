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
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let cornerRadius: CGFloat
    let textMinHeight: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            portraitView
                .frame(width: cardWidth, height: cardHeight)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: cornerRadius,
                        style: .continuous
                    )
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ThemeColor.textPrimary)
                    .lineLimit(1)

                Text(role)
                    .font(.caption)
                    .foregroundStyle(ThemeColor.sakura)
                    .lineLimit(1)

                Text(voiceActorSummary)
                    .font(.caption2)
                    .foregroundStyle(ThemeColor.textSecondary)
                    .lineLimit(1)
            }
            .frame(
                minWidth: cardWidth,
                maxWidth: cardWidth,
                minHeight: textMinHeight,
                alignment: .topLeading
            )
        }
        .frame(width: cardWidth, alignment: .leading)
    }

    @ViewBuilder
    private var portraitView: some View {
        if let imageURL {
            RemotePosterImageView(url: imageURL)
        } else {
            RoundedRectangle(
                cornerRadius: cornerRadius,
                style: .continuous
            )
                .fill(Color(.systemGray5))
                .overlay {
                    Image(systemName: "person.fill")
                        .foregroundStyle(ThemeColor.textTertiary)
                }
        }
    }
}

struct AnimeDetailRecommendationCardView: View {
    @Environment(\.animeDetailRecommendationsListMetrics) private var listMetrics

    let row: DetailRecommendationRow

    private let previewCardWidth: CGFloat = 160
    private let previewCardHeight: CGFloat = 240
    private let previewCornerRadius: CGFloat = 16
    private let previewTextMinHeight: CGFloat = 44

    var body: some View {
        switch row.context {
        case .preview:
            previewCard
        case .list:
            listCard
        }
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            posterView
                .frame(width: previewCardWidth, height: previewCardHeight)
                .clipShape(posterShape(cornerRadius: previewCornerRadius))

            VStack(alignment: .leading, spacing: 4) {
                Text(row.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ThemeColor.textPrimary)
                    .lineLimit(1)

                switch row.summary.displayText(for: .preview) {
                case let summaryText?:
                    Text(summaryText)
                        .font(.caption2)
                        .foregroundStyle(ThemeColor.textSecondary)
                        .lineLimit(1)
                case nil:
                    EmptyView()
                }
            }
            .frame(
                minWidth: previewCardWidth,
                maxWidth: previewCardWidth,
                minHeight: previewTextMinHeight,
                alignment: .topLeading
            )
        }
        .frame(width: previewCardWidth, alignment: .leading)
    }

    private var listCard: some View {
        VStack(alignment: .leading, spacing: AnimeDetailRecommendationsListMetrics.titleSpacing) {
            posterView
                .frame(width: listMetrics.cardWidth, height: listMetrics.posterHeight)
                .clipShape(posterShape(cornerRadius: previewCornerRadius))

            Text(row.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(ThemeColor.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: listMetrics.cardWidth, alignment: .leading)
        }
        .frame(width: listMetrics.cardWidth, alignment: .topLeading)
    }

    private func posterShape(cornerRadius: CGFloat) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    @ViewBuilder
    private var posterView: some View {
        if let imageURL = row.imageURL {
            RemotePosterImageView(url: imageURL)
        } else {
            RoundedRectangle(
                cornerRadius: previewCornerRadius,
                style: .continuous
            )
                .fill(Color(.systemGray5))
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(ThemeColor.textTertiary)
                }
        }
    }
}
