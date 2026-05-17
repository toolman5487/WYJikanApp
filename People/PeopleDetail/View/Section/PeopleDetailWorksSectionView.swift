//
//  PeopleDetailWorksSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/23.
//

import SwiftUI

struct PeopleDetailAnimeStaffSectionView: View {
    let viewModel: PeopleDetailViewModel
    let person: PeopleDetailDTO

    var body: some View {
        let positions = viewModel.animeStaffPositions(for: person)
        PeopleDetailHorizontalSection(title: "動畫作品") {
            ForEach(positions) { position in
                if let anime = position.anime {
                    NavigationLink {
                        AnimeDetailView(malId: anime.malId)
                    } label: {
                        PeopleDetailWorkCardView(
                            title: viewModel.workTitle(anime),
                            subtitle: viewModel.roleText(position.position),
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

struct PeopleDetailMangaStaffSectionView: View {
    let viewModel: PeopleDetailViewModel
    let person: PeopleDetailDTO

    var body: some View {
        let positions = viewModel.mangaStaffPositions(for: person)
        PeopleDetailHorizontalSection(title: "漫畫作品") {
            ForEach(positions) { position in
                if let manga = position.manga {
                    NavigationLink {
                        MangaDetailView(malId: manga.malId)
                    } label: {
                        PeopleDetailWorkCardView(
                            title: viewModel.workTitle(manga),
                            subtitle: viewModel.roleText(position.position),
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

private struct PeopleDetailWorkCardView: View {
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

struct PeopleDetailHorizontalSection<Content: View>: View {
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
