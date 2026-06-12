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
    let characterName: String
    @Binding var isShowingAnimeRoleList: Bool
    @State private var animeRoleListBounceProgress: CGFloat = 0

    var body: some View {
        AnimeDetailLinkedSection(
            title: "出演動畫",
            actionTitle: "查看全部"
        ) {
            animeRoleListDestination
        } content: {
            horizontalWorkScroll(
                roles: viewModel.previewAnimeRoles(for: character),
                showsEndHint: canShowAnimeRoleList,
                bounceProgress: $animeRoleListBounceProgress
            ) {
                isShowingAnimeRoleList = true
            }
        }
    }

    private var canShowAnimeRoleList: Bool {
        viewModel.canShowFullAnimeRoleList(for: character)
    }

    private var animeRoleListDestination: some View {
        CharacterDetailAnimeRolesListView(
            characterName: characterName,
            roles: viewModel.animeRoles(for: character),
            viewModel: viewModel
        )
    }
}

struct CharacterDetailMangaWorksSectionView: View {
    let viewModel: CharacterDetailViewModel
    let character: CharacterDetailDTO
    let characterName: String
    @Binding var isShowingMangaRoleList: Bool
    @State private var mangaRoleListBounceProgress: CGFloat = 0

    var body: some View {
        AnimeDetailLinkedSection(
            title: "出演漫畫",
            actionTitle: "查看全部"
        ) {
            mangaRoleListDestination
        } content: {
            horizontalWorkScroll(
                roles: viewModel.previewMangaRoles(for: character),
                showsEndHint: canShowMangaRoleList,
                bounceProgress: $mangaRoleListBounceProgress
            ) {
                isShowingMangaRoleList = true
            }
        }
    }

    private var canShowMangaRoleList: Bool {
        viewModel.canShowFullMangaRoleList(for: character)
    }

    private var mangaRoleListDestination: some View {
        CharacterDetailMangaRolesListView(
            characterName: characterName,
            roles: viewModel.mangaRoles(for: character),
            viewModel: viewModel
        )
    }
}

private extension CharacterDetailAnimeWorksSectionView {
    @ViewBuilder
    func horizontalWorkScroll(
        roles: [CharacterAnimeRoleDTO],
        showsEndHint: Bool,
        bounceProgress: Binding<CGFloat>,
        onReveal: @escaping () -> Void
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(roles) { role in
                    if let anime = role.anime {
                        NavigationLink {
                            AnimeDetailView(malId: anime.malId)
                        } label: {
                            CharacterDetailWorkCardView(
                                title: viewModel.workTitle(anime),
                                subtitle: viewModel.roleText(role.role),
                                imageURL: viewModel.thumbnailImageURL(from: anime.images),
                                cardWidth: 160,
                                cardHeight: 240,
                                cornerRadius: 16,
                                textMinHeight: 44
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if showsEndHint {
                    EndBounceHintView(
                        axis: .horizontal,
                        title: "完整作品",
                        subtitle: "繼續向右滑查看全部",
                        progress: bounceProgress.wrappedValue,
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
            isEnabled: showsEndHint,
            progress: bounceProgress
        ) {
            onReveal()
        }
    }
}

private extension CharacterDetailMangaWorksSectionView {
    @ViewBuilder
    func horizontalWorkScroll(
        roles: [CharacterMangaRoleDTO],
        showsEndHint: Bool,
        bounceProgress: Binding<CGFloat>,
        onReveal: @escaping () -> Void
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(roles) { role in
                    if let manga = role.manga {
                        NavigationLink {
                            MangaDetailView(malId: manga.malId)
                        } label: {
                            CharacterDetailWorkCardView(
                                title: viewModel.workTitle(manga),
                                subtitle: viewModel.roleText(role.role),
                                imageURL: viewModel.thumbnailImageURL(from: manga.images),
                                cardWidth: 160,
                                cardHeight: 240,
                                cornerRadius: 16,
                                textMinHeight: 44
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if showsEndHint {
                    EndBounceHintView(
                        axis: .horizontal,
                        title: "完整作品",
                        subtitle: "繼續向右滑查看全部",
                        progress: bounceProgress.wrappedValue,
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
            isEnabled: showsEndHint,
            progress: bounceProgress
        ) {
            onReveal()
        }
    }
}

struct CharacterDetailAnimeRolesListView: View {
    let characterName: String
    let roles: [CharacterAnimeRoleDTO]
    let viewModel: CharacterDetailViewModel

    var body: some View {
        DetailPosterGridListLayout {
            ForEach(roles) { role in
                if let anime = role.anime {
                    NavigationLink {
                        AnimeDetailView(malId: anime.malId)
                    } label: {
                        CharacterDetailWorkGridCardView(
                            title: viewModel.workTitle(anime),
                            subtitle: viewModel.roleText(role.role),
                            imageURL: viewModel.thumbnailImageURL(from: anime.images)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("\(characterName) 出演動畫")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CharacterDetailMangaRolesListView: View {
    let characterName: String
    let roles: [CharacterMangaRoleDTO]
    let viewModel: CharacterDetailViewModel

    var body: some View {
        DetailPosterGridListLayout {
            ForEach(roles) { role in
                if let manga = role.manga {
                    NavigationLink {
                        MangaDetailView(malId: manga.malId)
                    } label: {
                        CharacterDetailWorkGridCardView(
                            title: viewModel.workTitle(manga),
                            subtitle: viewModel.roleText(role.role),
                            imageURL: viewModel.thumbnailImageURL(from: manga.images)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("\(characterName) 出演漫畫")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CharacterDetailWorkGridCardView: View {
    @Environment(\.detailPosterGridListMetrics) private var metrics

    let title: String
    let subtitle: String
    let imageURL: URL?

    var body: some View {
        CharacterDetailWorkCardView(
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

struct CharacterDetailWorkCardView: View {
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
            RemotePosterImageView(
                url: imageURL,
                fixedSize: CGSize(width: cardWidth, height: cardHeight)
            )
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
