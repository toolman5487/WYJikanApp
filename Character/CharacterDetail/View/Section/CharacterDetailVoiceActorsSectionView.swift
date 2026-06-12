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
    let characterName: String
    @Binding var isShowingVoiceActorList: Bool
    @State private var voiceActorListBounceProgress: CGFloat = 0

    private let avatarSize: CGFloat = 84

    var body: some View {
        AnimeDetailLinkedSection(
            title: "聲優",
            actionTitle: "查看全部"
        ) {
            voiceActorListDestination
        } content: {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(viewModel.previewVoiceActors(for: character)) { voice in
                        if let person = voice.person {
                            NavigationLink {
                                PeopleDetailView(malId: person.malId)
                            } label: {
                                CharacterDetailVoiceActorCardView(
                                    name: viewModel.personName(person),
                                    language: viewModel.languageText(voice.language),
                                    imageURL: viewModel.thumbnailImageURL(from: person.images),
                                    avatarSize: avatarSize
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if canShowVoiceActorList {
                        EndBounceHintView(
                            axis: .horizontal,
                            title: "完整聲優",
                            subtitle: "繼續向右滑查看全部",
                            progress: voiceActorListBounceProgress,
                            width: 92,
                            height: avatarSize + 52,
                            cornerRadius: 16
                        )
                    }
                }
                .padding(.vertical, 4)
            }
            .onEndBounce(
                axis: .horizontal,
                isEnabled: canShowVoiceActorList,
                progress: $voiceActorListBounceProgress
            ) {
                isShowingVoiceActorList = true
            }
        }
    }

    private var canShowVoiceActorList: Bool {
        viewModel.canShowFullVoiceActorList(for: character)
    }

    private var voiceActorListDestination: some View {
        CharacterDetailVoiceActorsListView(
            characterName: characterName,
            voices: viewModel.voiceActors(for: character),
            viewModel: viewModel
        )
    }
}

struct CharacterDetailVoiceActorsListView: View {
    let characterName: String
    let voices: [CharacterVoiceActorDTO]
    let viewModel: CharacterDetailViewModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(voices) { voice in
                    if let person = voice.person {
                        NavigationLink {
                            PeopleDetailView(malId: person.malId)
                        } label: {
                            HStack(alignment: .top, spacing: 16) {
                                voiceActorImage(person)
                                    .frame(width: 82, height: 104)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                                VStack(alignment: .leading, spacing: 8) {
                                    Text(viewModel.personName(person))
                                        .font(.headline)
                                        .foregroundStyle(ThemeColor.textPrimary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)

                                    Text(viewModel.languageText(voice.language))
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
        .navigationTitle("\(characterName) 聲優")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func voiceActorImage(_ person: CharacterPersonDTO) -> some View {
        if let imageURL = viewModel.thumbnailImageURL(from: person.images) {
            RemotePosterImageView(
                url: imageURL,
                fixedSize: CGSize(width: 82, height: 104)
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

private struct CharacterDetailVoiceActorCardView: View {
    let name: String
    let language: String
    let imageURL: URL?
    let avatarSize: CGFloat

    var body: some View {
        VStack(spacing: 8) {
            avatarView
                .frame(width: avatarSize, height: avatarSize)
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
            RemotePosterImageView(
                url: imageURL,
                fixedSize: CGSize(width: avatarSize, height: avatarSize)
            )
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
