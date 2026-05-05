//
//  HomeTrendingAnimeListFeaturedSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu 2026/5/5.
//

import SwiftUI

struct HomeTrendingAnimeListFeaturedSectionView: View {
    let title: String
    let items: [HomeTrendingAnimeListItem]
    let onTap: (HomeTrendingAnimeListItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(ThemeColor.textPrimary)

            if let first = items.first {
                featuredHeroCard(first)
            }

            if items.count > 1 {
                HStack(spacing: 12) {
                    ForEach(Array(items.dropFirst())) { item in
                        compactFeaturedCard(item)
                    }
                }
            }
        }
    }

    private func featuredHeroCard(_ item: HomeTrendingAnimeListItem) -> some View {
        Button {
            onTap(item)
        } label: {
            ZStack(alignment: .bottomLeading) {
                posterView(for: item)
                    .frame(height: 340)
                    .overlay {
                        LinearGradient(
                            colors: [.clear, Color.black.opacity(0.78)],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                    }

                VStack(alignment: .leading, spacing: 8) {
                    if let rank = item.rank {
                        rankBadge(rank)
                    }

                    Text(item.title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.white)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        if let typeText = item.typeText {
                            chip(typeText)
                        }
                        if let scoreText = item.scoreText {
                            chip("★ \(scoreText)")
                        }
                        if let episodeText = item.episodeText {
                            chip(episodeText)
                        }
                    }

                    if let synopsisPreview = item.synopsisPreview {
                        Text(synopsisPreview)
                            .font(.footnote)
                            .foregroundStyle(Color.white.opacity(0.92))
                            .lineLimit(3)
                    }
                }
                .padding(18)
            }
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func compactFeaturedCard(_ item: HomeTrendingAnimeListItem) -> some View {
        Button {
            onTap(item)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .topLeading) {
                    posterView(for: item)
                        .frame(height: 190)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    if let rank = item.rank {
                        rankBadge(rank)
                            .padding(10)
                    }
                }

                Text(item.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(ThemeColor.textPrimary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    if let scoreText = item.scoreText {
                        chip("★ \(scoreText)")
                    }
                    if let typeText = item.typeText {
                        chip(typeText)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private func posterView(for item: HomeTrendingAnimeListItem) -> some View {
        Group {
            if let imageURL = item.imageURL {
                RemotePosterImageView(url: imageURL)
            } else {
                Color(.secondarySystemFill)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .background(Color(.secondarySystemBackground))
    }

    private func rankBadge(_ rank: Int) -> some View {
        Text("#\(rank)")
            .font(.caption.weight(.bold))
            .foregroundStyle(ThemeColor.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(ThemeColor.sakuraGlassStrong)
            .clipShape(Capsule())
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.16))
            .clipShape(Capsule())
    }
}
