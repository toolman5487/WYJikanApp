//
//  GenreAnimeSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/9.
//

import SwiftUI

struct GenreAnimeSectionView: View {

    // MARK: - Properties

    let section: AnimeGenreSection
    let favoriteIDs: Set<Int>

    private let cardWidth: CGFloat = 200 * (2.0 / 3.0)

    // MARK: - Body

    var body: some View {
        Group {
            if section.items.isEmpty {
                contentSkeletonView
            } else {
                contentView
            }
        }
    }

    // MARK: - Private Methods

    private var contentView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(section.items.prefix(10)) { item in
                    GenreAnimePosterCardView(
                        item: item,
                        cardWidth: cardWidth,
                        cardHeight: 200,
                        cardCornerRadius: 16,
                        isFavorite: favoriteIDs.contains(item.id)
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var contentSkeletonView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.systemGray5))
                        .frame(width: cardWidth, height: 200)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - GenreAnimeSectionHeaderView

struct GenreAnimeSectionHeaderView: View {

    // MARK: - Properties

    let section: AnimeGenreSection

    // MARK: - Body

    var body: some View {
        NavigationLink {
            AnimeCategoryDetailView(genre: section.genre)
        } label: {
            GlassSectionHeaderView(
                title: titleText,
                showsDisclosureIndicator: true
            )
        }
        .buttonStyle(.plain)
        .background(Color(.systemBackground).opacity(0.001))
    }

    // MARK: - Private Methods

    private var titleText: String {
        section.genre.name ?? "未分類"
    }
}

#Preview {
    GenreAnimeSectionView(
        section: AnimeGenreSection(
            genre: AnimeListGenreDTO(malId: 1, name: "Action"),
            items: [
                AnimeListRandomDTO(
                    malId: 1,
                    title: "Sample",
                    titleEnglish: nil,
                    titleJapanese: "サンプル",
                    synopsis: nil,
                    type: "TV",
                    score: 8.5,
                    rank: nil,
                    popularity: nil,
                    members: nil,
                    episodes: nil,
                    images: nil,
                    genres: nil
                )
            ]
        ),
        favoriteIDs: []
    )
}
