//
//  PeopleDetailVoiceRolesSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/23.
//

import SwiftUI

struct PeopleDetailVoiceRolesSectionView: View {
    let viewModel: PeopleDetailViewModel
    let person: PeopleDetailDTO
    let personName: String
    @Binding var isShowingVoiceRoleList: Bool
    @State private var voiceRoleListBounceProgress: CGFloat = 0

    var body: some View {
        AnimeDetailLinkedSection(
            title: "配音角色",
            actionTitle: "查看全部"
        ) {
            voiceRoleListDestination
        } content: {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(viewModel.previewVoiceRoles(for: person)) { role in
                        if let character = role.character {
                            NavigationLink {
                                CharacterDetailView(malId: character.malId)
                            } label: {
                                PeopleDetailVoiceRoleCardView(
                                    characterName: viewModel.characterName(character),
                                    workTitle: role.anime.map(viewModel.workTitle) ?? "-",
                                    role: viewModel.roleText(role.role),
                                    imageURL: viewModel.imageURL(from: character.images),
                                    cardWidth: 160,
                                    cardHeight: 240,
                                    cornerRadius: 16,
                                    textMinHeight: 60
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if canShowVoiceRoleList {
                        EndBounceHintView(
                            axis: .horizontal,
                            title: "完整配音",
                            subtitle: "繼續向右滑查看全部",
                            progress: voiceRoleListBounceProgress,
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
                isEnabled: canShowVoiceRoleList,
                progress: $voiceRoleListBounceProgress
            ) {
                isShowingVoiceRoleList = true
            }
        }
    }

    private var canShowVoiceRoleList: Bool {
        viewModel.canShowFullVoiceRoleList(for: person)
    }

    private var voiceRoleListDestination: some View {
        PeopleDetailVoiceRolesListView(
            personName: personName,
            roles: viewModel.voiceRolesWithCharacter(for: person),
            viewModel: viewModel
        )
    }
}

struct PeopleDetailVoiceRolesListView: View {
    let personName: String
    let roles: [PeopleVoiceRoleDTO]
    let viewModel: PeopleDetailViewModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(roles) { role in
                    if let character = role.character {
                        NavigationLink {
                            CharacterDetailView(malId: character.malId)
                        } label: {
                            HStack(alignment: .top, spacing: 16) {
                                voiceRoleImage(character)
                                    .frame(width: 82, height: 104)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                                VStack(alignment: .leading, spacing: 8) {
                                    Text(viewModel.characterName(character))
                                        .font(.headline)
                                        .foregroundStyle(ThemeColor.textPrimary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)

                                    Text(role.anime.map(viewModel.workTitle) ?? "-")
                                        .font(.caption)
                                        .foregroundStyle(ThemeColor.textSecondary)
                                        .lineLimit(2)

                                    Text(viewModel.roleText(role.role))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(ThemeColor.sakura)
                                        .lineLimit(1)
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
        .navigationTitle("\(personName) 配音角色")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func voiceRoleImage(_ character: PeopleRelatedCharacterDTO) -> some View {
        if let imageURL = viewModel.imageURL(from: character.images) {
            RemotePosterImageView(
                url: imageURL,
                fixedSize: CGSize(width: 82, height: 104)
            )
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray5))
                .overlay {
                    Image(systemName: "person.crop.rectangle")
                        .foregroundStyle(ThemeColor.textTertiary)
                }
        }
    }
}

struct PeopleDetailVoiceRoleCardView: View {
    let characterName: String
    let workTitle: String
    let role: String
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
                Text(characterName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ThemeColor.textPrimary)
                    .lineLimit(2)

                Text(workTitle)
                    .font(.caption2)
                    .foregroundStyle(ThemeColor.textSecondary)
                    .lineLimit(1)

                Text(role)
                    .font(.caption2)
                    .foregroundStyle(ThemeColor.textTertiary)
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
                    Image(systemName: "person.crop.rectangle")
                        .foregroundStyle(ThemeColor.textTertiary)
                }
        }
    }
}
