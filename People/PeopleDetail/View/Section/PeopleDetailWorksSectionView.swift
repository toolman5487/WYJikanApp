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
                            imageURL: viewModel.imageURL(from: anime.images)
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
                            imageURL: viewModel.imageURL(from: manga.images)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            posterView
                .frame(width: 112, height: 156)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(ThemeColor.textPrimary)
                .lineLimit(2)
                .frame(width: 112, alignment: .leading)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(ThemeColor.textSecondary)
                .lineLimit(1)
                .frame(width: 112, alignment: .leading)
        }
    }

    @ViewBuilder
    private var posterView: some View {
        if let imageURL {
            RemotePosterImageView(url: imageURL)
        } else {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
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
                .padding(.vertical, 2)
            }
        }
    }
}
