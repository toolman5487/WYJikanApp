//
//  AnimeDetailCharactersSectionView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/14.
//

import Foundation
import SwiftUI

struct AnimeDetailCharactersSectionView: View {
    let viewModel: AnimeDetailViewModel
    let animeTitle: String

    var body: some View {
        AnimeDetailLinkedSection(
            title: "角色與聲優",
            actionTitle: "查看全部"
        ) {
            AnimeDetailCharactersListView(
                animeTitle: animeTitle,
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
                                    voiceActorSummary: viewModel.voiceActorSummary(for: role),
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

private struct AnimeDetailCharactersListView: View {
    let animeTitle: String
    let roles: [AnimeCharacterRoleDTO]
    let viewModel: AnimeDetailViewModel

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

                                    Text(viewModel.voiceActorSummary(for: role))
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
        .navigationTitle("\(animeTitle) 角色")
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
