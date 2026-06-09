//
//  MangaDetailAdditionalSectionsView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/1.
//

import SwiftUI

struct MangaDetailBasicInfoSectionView: View {
    let viewModel: MangaDetailViewModel
    let manga: MangaDetailDTO

    var body: some View {
        AnimeDetailSectionCard("基本資訊") {
            VStack(spacing: 12) {
                AnimeDetailInfoRow(
                    title: "連載期間",
                    value: viewModel.publishedPeriodDisplayText(for: manga),
                    subtitle: viewModel.publishingStateText(for: manga)
                )
                AnimeDetailInfoRow(title: "卷數", value: viewModel.volumesDisplayText(for: manga))
                AnimeDetailInfoRow(title: "話數", value: viewModel.chaptersDisplayText(for: manga))
                AnimeDetailInfoRow(title: "狀態", value: viewModel.mangaStatusDisplayText(for: manga))
            }
        }
    }
}

struct MangaDetailCharactersSectionView: View {
    let viewModel: MangaDetailViewModel
    let mangaTitle: String

    var body: some View {
        AnimeDetailLinkedSection(
            title: "角色",
            actionTitle: "查看全部"
        ) {
            MangaDetailCharactersListView(
                mangaTitle: mangaTitle,
                roles: viewModel.allCharacterRoles,
                viewModel: viewModel
            )
        } content: {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(viewModel.previewCharacterRoles) { role in
                        if let character = role.character {
                            NavigationLink {
                                CharacterDetailView(malId: character.malId)
                            } label: {
                                AnimeDetailCharacterCardView(
                                    name: viewModel.characterName(character),
                                    role: viewModel.characterRoleText(role),
                                    voiceActorSummary: viewModel.characterFavoriteText(role),
                                    imageURL: viewModel.characterImageURL(character),
                                    cardWidth: 160,
                                    cardHeight: 240,
                                    cornerRadius: 16,
                                    textMinHeight: 56
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

private struct MangaDetailCharactersListView: View {
    let mangaTitle: String
    let roles: [MangaCharacterRoleDTO]
    let viewModel: MangaDetailViewModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(roles) { role in
                    if let character = role.character {
                        NavigationLink {
                            CharacterDetailView(malId: character.malId)
                        } label: {
                            HStack(alignment: .top, spacing: 16) {
                                characterImage(character)
                                    .frame(width: 82, height: 104)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                                VStack(alignment: .leading, spacing: 8) {
                                    Text(viewModel.characterName(character))
                                        .font(.headline)
                                        .foregroundStyle(ThemeColor.textPrimary)
                                        .lineLimit(1)
                                        .multilineTextAlignment(.leading)

                                    Text(viewModel.characterRoleText(role))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(ThemeColor.sakura)

                                    Text(viewModel.characterFavoriteText(role))
                                        .font(.caption)
                                        .foregroundStyle(ThemeColor.textSecondary)
                                        .lineLimit(1)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer(minLength: 0)
                            }
                            .padding(16)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("\(mangaTitle) 角色")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func characterImage(_ character: AnimeCharacterEntryDTO) -> some View {
        if let imageURL = viewModel.characterImageURL(character) {
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

struct MangaDetailPicturesSectionView: View {
    let viewModel: MangaDetailViewModel
    let onTapImage: (Int) -> Void

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    var body: some View {
        AnimeDetailSectionCard("圖片") {
            LazyVGrid(columns: gridColumns, alignment: .center, spacing: 12) {
                ForEach(Array(viewModel.pictureItems.enumerated()), id: \.element.id) { index, item in
                    DetailPictureGridItemView(url: item.url) {
                        onTapImage(index)
                    }
                }
            }
        }
    }
}

struct MangaDetailRecommendationsSectionView: View {
    let viewModel: MangaDetailViewModel
    let mangaTitle: String

    var body: some View {
        AnimeDetailLinkedSection(
            title: "你可能也喜歡",
            actionTitle: "更多推薦"
        ) {
            MangaDetailRecommendationsListView(
                mangaTitle: mangaTitle,
                recommendations: viewModel.allRecommendations,
                viewModel: viewModel
            )
        } content: {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(viewModel.previewRecommendations) { recommendation in
                        if let entry = recommendation.entry {
                            NavigationLink {
                                MangaDetailView(malId: entry.malId)
                            } label: {
                                AnimeDetailRecommendationCardView(
                                    title: viewModel.recommendationTitle(recommendation),
                                    summary: viewModel.recommendationSummaryText(recommendation),
                                    imageURL: viewModel.recommendationImageURL(recommendation),
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
                .padding(.vertical, 4)
            }
        }
    }
}

private struct MangaDetailRecommendationsListView: View {
    let mangaTitle: String
    let recommendations: [MangaRecommendationDTO]
    let viewModel: MangaDetailViewModel

    private let columns = [
        GridItem(
            .adaptive(
                minimum: 160,
                maximum: 160
            ),
            spacing: 16,
            alignment: .top
        )
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 20) {
                ForEach(recommendations) { recommendation in
                    if let entry = recommendation.entry {
                        NavigationLink {
                            MangaDetailView(malId: entry.malId)
                        } label: {
                            VStack(alignment: .leading, spacing: 12) {
                                recommendationPoster(recommendation)
                                    .frame(width: 160, height: 240)
                                    .clipShape(
                                        RoundedRectangle(
                                            cornerRadius: 16,
                                            style: .continuous
                                        )
                                    )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(viewModel.recommendationTitle(recommendation))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(ThemeColor.textPrimary)
                                        .lineLimit(1)

                                    Text(viewModel.recommendationSummaryText(recommendation))
                                        .font(.caption)
                                        .foregroundStyle(ThemeColor.textSecondary)
                                        .lineLimit(3)
                                }
                                .frame(
                                    minWidth: 160,
                                    maxWidth: 160,
                                    minHeight: 72,
                                    alignment: .topLeading
                                )
                            }
                            .frame(width: 160, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("\(mangaTitle) 推薦")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func recommendationPoster(_ recommendation: MangaRecommendationDTO) -> some View {
        if let imageURL = viewModel.recommendationImageURL(recommendation) {
            RemotePosterImageView(url: imageURL)
        } else {
            RoundedRectangle(
                cornerRadius: 16,
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
