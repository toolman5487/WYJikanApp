//
//  MangaDetailCharactersListView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/11.
//

import SwiftUI

struct MangaDetailCharactersListView: View {

    // MARK: - Properties

    let mangaTitle: String
    let roles: [MangaCharacterRoleDTO]
    let viewModel: MangaDetailViewModel

    // MARK: - Body

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
                                    .frame(width: 84, height: 104)
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

    // MARK: - Private Views

    @ViewBuilder
    private func characterImage(_ character: AnimeCharacterEntryDTO) -> some View {
        if let imageURL = viewModel.characterImageURL(character) {
            RemotePosterImageView(
                url: imageURL,
                fixedSize: CGSize(width: 84, height: 104)
            )
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
