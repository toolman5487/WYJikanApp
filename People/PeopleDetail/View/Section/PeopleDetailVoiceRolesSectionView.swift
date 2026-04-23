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
                PeopleDetailVoiceRoleCardView(
                    characterName: role.character.map(viewModel.characterName) ?? "-",
                    workTitle: role.anime.map(viewModel.workTitle) ?? "-",
                    role: viewModel.roleText(role.role),
                    imageURL: viewModel.imageURL(from: role.character?.images)
                )
            }
        }
    }
}

private struct PeopleDetailVoiceRoleCardView: View {
    let characterName: String
    let workTitle: String
    let role: String
    let imageURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            posterView
                .frame(width: 112, height: 156)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(characterName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(ThemeColor.textPrimary)
                .lineLimit(2)
                .frame(width: 112, alignment: .leading)

            Text(workTitle)
                .font(.caption2)
                .foregroundStyle(ThemeColor.textSecondary)
                .lineLimit(1)
                .frame(width: 112, alignment: .leading)

            Text(role)
                .font(.caption2)
                .foregroundStyle(ThemeColor.textTertiary)
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
                    Image(systemName: "person.crop.rectangle")
                        .foregroundStyle(ThemeColor.textTertiary)
                }
        }
    }
}
