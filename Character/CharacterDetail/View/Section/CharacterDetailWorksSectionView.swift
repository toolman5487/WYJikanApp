//
//  CharacterDetailWorksSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/22.
//

import SwiftUI

struct CharacterDetailAnimeWorksSectionView: View {
    let viewModel: CharacterDetailViewModel
    let character: CharacterDetailDTO

    var body: some View {
        let roles = viewModel.animeRoles(for: character)
        CharacterDetailHorizontalSection(title: "出演動畫") {
            ForEach(roles) { role in
                if let anime = role.anime {
                    NavigationLink {
                        AnimeDetailView(malId: anime.malId)
                    } label: {
                        CharacterDetailWorkCardView(
                            title: viewModel.workTitle(anime),
                            subtitle: viewModel.roleText(role.role),
                            imageURL: viewModel.imageURL(from: anime.images),
                            cardWidth: 160,
                            cardHeight: 240,
                            cornerRadius: 16,
                            textMinHeight: 44
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct CharacterDetailMangaWorksSectionView: View {
    let viewModel: CharacterDetailViewModel
    let character: CharacterDetailDTO

    var body: some View {
        let roles = viewModel.mangaRoles(for: character)
        CharacterDetailHorizontalSection(title: "出演漫畫") {
            ForEach(roles) { role in
                if let manga = role.manga {
                    NavigationLink {
                        MangaDetailView(malId: manga.malId)
                    } label: {
                        CharacterDetailWorkCardView(
                            title: viewModel.workTitle(manga),
                            subtitle: viewModel.roleText(role.role),
                            imageURL: viewModel.imageURL(from: manga.images),
                            cardWidth: 160,
                            cardHeight: 240,
                            cornerRadius: 16,
                            textMinHeight: 44
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct CharacterDetailWorkCardView: View {
    let title: String
    let subtitle: String
    let imageURL: URL?
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let cornerRadius: CGFloat
    let textMinHeight: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            posterView
                .frame(width: cardWidth, height: cardHeight)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: cornerRadius,
                        style: .continuous
                    )
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ThemeColor.textPrimary)
                    .lineLimit(2)

                Text(subtitle)
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
    private var posterView: some View {
        if let imageURL {
            RemotePosterImageView(url: imageURL)
        } else {
            RoundedRectangle(
                cornerRadius: cornerRadius,
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

struct CharacterDetailHorizontalSection<Content: View>: View {
    let title: String
    private let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        AnimeDetailSectionCard(title) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    content
                }
                .padding(.vertical, 4)
            }
        }
    }
}
