//
//  MangaDetailPublicationSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/1.
//

import SwiftUI

struct MangaDetailPublicationSectionView: View {

    // MARK: - Properties

    let viewModel: MangaDetailViewModel
    let manga: MangaDetailDTO

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if viewModel.hasPublicationInfo(for: manga) {
                let authorsText = viewModel.joinedNames(from: manga.authors)
                let serializationsText = viewModel.joinedNames(from: manga.serializations)
                let genresText = viewModel.joinedNames(from: manga.genres)
                let demographicsText = viewModel.joinedNames(from: manga.demographics)
                AnimeDetailSectionCard("出版資訊") {
                    VStack(spacing: 12) {
                        MangaDetailAuthorInfoRow(
                            authors: viewModel.authorDisplayItems(for: manga),
                            fallbackText: authorsText,
                            name: viewModel.authorDisplayName
                        )
                        AnimeDetailInfoRow(title: "連載", value: serializationsText)
                        AnimeDetailInfoRow(title: "類型", value: genresText)
                        AnimeDetailInfoRow(title: "族群", value: demographicsText)
                    }
                }
            }
            if viewModel.hasThemes(for: manga) {
                VStack(alignment: .leading, spacing: 16) {
                    CapsuleTagScrollView(
                        tags: viewModel.themeDisplayItems(for: manga),
                        title: { $0.name ?? "—" }
                    )
                    if !viewModel.hasSynopsis(for: manga), let url = viewModel.malWorkPageURL(for: manga) {
                        MALWorkPageOpenButton(url: url)
                    }
                }
            }
            if !viewModel.hasSynopsis(for: manga), !viewModel.hasThemes(for: manga),
               let url = viewModel.malWorkPageURL(for: manga) {
                MALWorkPageOpenButton(url: url)
            }
        }
    }
}

private struct MangaDetailAuthorInfoRow: View {
    let authors: [AnimeRelatedEntityDTO]
    let fallbackText: String
    let name: (AnimeRelatedEntityDTO) -> String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("作者")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ThemeColor.textSecondary)
                .frame(width: 72, alignment: .leading)

            if authors.isEmpty {
                Text(fallbackText)
                    .font(.subheadline)
                    .foregroundStyle(ThemeColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(authors) { author in
                            NavigationLink {
                                PeopleDetailView(malId: author.malId)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "person.crop.circle")
                                        .font(.caption.weight(.semibold))
                                    Text(name(author))
                                        .lineLimit(1)
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(ThemeColor.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(ThemeColor.sakura.opacity(0.18))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .accessibilityElement(children: .contain)
    }
}
