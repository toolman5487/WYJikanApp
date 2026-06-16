//
//  MangaDetailCharactersSectionView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/11.
//

import SwiftUI

struct MangaDetailCharactersSectionView: View {

    // MARK: - Properties

    let viewModel: MangaDetailViewModel
    let mangaTitle: String
    @Binding var isShowingCharacterList: Bool
    @State private var characterListBounceProgress: CGFloat = 0

    // MARK: - Body

    var body: some View {
        AnimeDetailLinkedSection(
            title: "角色",
            actionTitle: "查看全部"
        ) {
            characterListDestination
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

                    if canShowCharacterList {
                        EndBounceHintView(
                            axis: .horizontal,
                            title: "完整角色",
                            subtitle: "繼續向右滑查看全部",
                            progress: characterListBounceProgress,
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
                isEnabled: canShowCharacterList,
                progress: $characterListBounceProgress
            ) {
                isShowingCharacterList = true
            }
        }
    }

    // MARK: - Private Views

    private var characterListDestination: some View {
        MangaDetailCharactersListView(
            mangaTitle: mangaTitle,
            roles: viewModel.allCharacterRoles,
            viewModel: viewModel
        )
    }

    // MARK: - Private Methods

    private var canShowCharacterList: Bool {
        viewModel.allCharacterRoles.count > viewModel.previewCharacterRoles.count
    }
}
