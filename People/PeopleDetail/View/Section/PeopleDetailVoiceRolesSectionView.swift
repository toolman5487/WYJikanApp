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

    var body: some View {
        let roles = viewModel.voiceRoles(for: person)
        PeopleDetailHorizontalSection(title: "配音角色") {
            ForEach(roles) { role in
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
        }
    }
}

private struct PeopleDetailVoiceRoleCardView: View {
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
            RemotePosterImageView(url: imageURL)
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
