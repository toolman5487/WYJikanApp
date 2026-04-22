//
//  CharacterDetailVoiceActorsSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/22.
//

import SwiftUI

struct CharacterDetailVoiceActorsSectionView: View {
    let viewModel: CharacterDetailViewModel
    let character: CharacterDetailDTO

    var body: some View {
        let voices = viewModel.voiceActors(for: character)
        CharacterDetailHorizontalSection(title: "聲優") {
            ForEach(voices) { voice in
                if let person = voice.person {
                    CharacterDetailVoiceActorCardView(
                        name: viewModel.personName(person),
                        language: viewModel.languageText(voice.language),
                        imageURL: viewModel.imageURL(from: person.images)
                    )
                }
            }
        }
    }
}

private struct CharacterDetailVoiceActorCardView: View {
    let name: String
    let language: String
    let imageURL: URL?

    var body: some View {
        VStack(spacing: 8) {
            avatarView
                .frame(width: 84, height: 84)
                .clipShape(Circle())

            Text(name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(ThemeColor.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 92)

            Text(language)
                .font(.caption2)
                .foregroundStyle(ThemeColor.textSecondary)
                .lineLimit(1)
                .frame(width: 92)
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        if let imageURL {
            RemotePosterImageView(url: imageURL)
        } else {
            Circle()
                .fill(Color(.systemGray5))
                .overlay {
                    Image(systemName: "person.fill")
                        .foregroundStyle(ThemeColor.textTertiary)
                }
        }
    }
}
