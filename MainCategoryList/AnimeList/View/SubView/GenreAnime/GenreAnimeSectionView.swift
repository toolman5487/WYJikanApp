//
//  GenreAnimeSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/9.
//

import SwiftUI

struct GenreAnimeSectionView: View {
    // MARK: - Constants

    private static let cardHeight: CGFloat = 200
    private static let posterAspectRatio: CGFloat = 2.0 / 3.0
    private static let cardCornerRadius: CGFloat = 16
    private static let cardSpacing: CGFloat = 12

    // MARK: - Properties

    let section: AnimeGenreSection
    let favoriteIDs: Set<Int>

    private static var cardWidth: CGFloat {
        cardHeight * posterAspectRatio
    }

    // MARK: - View

    var body: some View {
        Group {
            if section.items.isEmpty {
                contentSkeletonView
            } else {
                contentView
            }
        }
    }

    private var contentView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Self.cardSpacing) {
                ForEach(section.items.prefix(10)) { item in
                    GenreAnimePosterCardView(
                        item: item,
                        cardWidth: Self.cardWidth,
                        cardHeight: Self.cardHeight,
                        cardCornerRadius: Self.cardCornerRadius,
                        isFavorite: favoriteIDs.contains(item.id)
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var contentSkeletonView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Self.cardSpacing) {
                ForEach(0..<6, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: Self.cardCornerRadius, style: .continuous)
                        .fill(Color(.systemGray5))
                        .frame(width: Self.cardWidth, height: Self.cardHeight)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

struct GenreAnimeSectionHeaderView: View {
    let section: AnimeGenreSection

    private var titleText: String {
        section.genre.name ?? "未分類"
    }

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
