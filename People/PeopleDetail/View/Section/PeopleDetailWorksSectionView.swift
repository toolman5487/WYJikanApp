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
    let personName: String
    @Binding var isShowingAnimeStaffList: Bool
    @State private var animeStaffListBounceProgress: CGFloat = 0

    var body: some View {
        AnimeDetailLinkedSection(
            title: "動畫作品",
            actionTitle: "查看全部"
        ) {
            animeStaffListDestination
        } content: {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(viewModel.previewAnimeStaffPositions(for: person)) { position in
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

                    if canShowAnimeStaffList {
                        EndBounceHintView(
                            axis: .horizontal,
                            title: "完整作品",
                            subtitle: "繼續向右滑查看全部",
                            progress: animeStaffListBounceProgress,
                            width: 160,
                            height: 240,
                            cornerRadius: 16
                        )
                    }
                }
                .padding(.vertical, 4)
            }
            .onEndBounce(
                axis: .horizontal,
                isEnabled: canShowAnimeStaffList,
                progress: $animeStaffListBounceProgress
            ) {
                isShowingAnimeStaffList = true
            }
        }
    }

    private var canShowAnimeStaffList: Bool {
        viewModel.canShowFullAnimeStaffList(for: person)
    }

    private var animeStaffListDestination: some View {
        PeopleDetailAnimeStaffListView(
            personName: personName,
            positions: viewModel.animeStaffPositions(for: person),
            viewModel: viewModel
        )
    }
}

struct PeopleDetailMangaStaffSectionView: View {
    let viewModel: PeopleDetailViewModel
    let person: PeopleDetailDTO
    let personName: String
    @Binding var isShowingMangaStaffList: Bool
    @State private var mangaStaffListBounceProgress: CGFloat = 0

    var body: some View {
        AnimeDetailLinkedSection(
            title: "漫畫作品",
            actionTitle: "查看全部"
        ) {
            mangaStaffListDestination
        } content: {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(viewModel.previewMangaStaffPositions(for: person)) { position in
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

                    if canShowMangaStaffList {
                        EndBounceHintView(
                            axis: .horizontal,
                            title: "完整作品",
                            subtitle: "繼續向右滑查看全部",
                            progress: mangaStaffListBounceProgress,
                            width: 160,
                            height: 240,
                            cornerRadius: 16
                        )
                    }
                }
                .padding(.vertical, 4)
            }
            .onEndBounce(
                axis: .horizontal,
                isEnabled: canShowMangaStaffList,
                progress: $mangaStaffListBounceProgress
            ) {
                isShowingMangaStaffList = true
            }
        }
    }

    private var canShowMangaStaffList: Bool {
        viewModel.canShowFullMangaStaffList(for: person)
    }

    private var mangaStaffListDestination: some View {
        PeopleDetailMangaStaffListView(
            personName: personName,
            positions: viewModel.mangaStaffPositions(for: person),
            viewModel: viewModel
        )
    }
}

struct PeopleDetailAnimeStaffListView: View {
    let personName: String
    let positions: [PeopleAnimeStaffPositionDTO]
    let viewModel: PeopleDetailViewModel

    var body: some View {
        DetailPosterGridListLayout {
            ForEach(positions) { position in
                if let anime = position.anime {
                    NavigationLink {
                        AnimeDetailView(malId: anime.malId)
                    } label: {
                        PeopleDetailWorkGridCardView(
                            title: viewModel.workTitle(anime),
                            subtitle: viewModel.roleText(position.position),
                            imageURL: viewModel.imageURL(from: anime.images)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("\(personName) 動畫作品")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PeopleDetailMangaStaffListView: View {
    let personName: String
    let positions: [PeopleMangaStaffPositionDTO]
    let viewModel: PeopleDetailViewModel

    var body: some View {
        DetailPosterGridListLayout {
            ForEach(positions) { position in
                if let manga = position.manga {
                    NavigationLink {
                        MangaDetailView(malId: manga.malId)
                    } label: {
                        PeopleDetailWorkGridCardView(
                            title: viewModel.workTitle(manga),
                            subtitle: viewModel.roleText(position.position),
                            imageURL: viewModel.imageURL(from: manga.images)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("\(personName) 漫畫作品")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PeopleDetailWorkGridCardView: View {
    @Environment(\.detailPosterGridListMetrics) private var metrics

    let title: String
    let subtitle: String
    let imageURL: URL?

    var body: some View {
        PeopleDetailWorkCardView(
            title: title,
            subtitle: subtitle,
            imageURL: imageURL,
            cardWidth: metrics.cardWidth,
            cardHeight: metrics.posterHeight,
            cornerRadius: 16,
            textMinHeight: 44
        )
    }
}

struct PeopleDetailWorkCardView: View {
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
