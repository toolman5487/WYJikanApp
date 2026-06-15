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

    private static var cardWidth: CGFloat {
        cardHeight * posterAspectRatio
    }

    // MARK: - Properties

    let section: AnimeGenreSection
    let favoriteIDs: Set<Int>
    let skeletonItemCount: Int
    let onOpenCategoryDetail: () -> Void

    @State private var endBounceProgress: CGFloat = 0

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

                EndBounceHintView(
                    axis: .horizontal,
                    title: endBounceTitle,
                    subtitle: "繼續往右拉查看分類",
                    progress: endBounceProgress,
                    width: Self.cardWidth,
                    height: Self.cardHeight,
                    cornerRadius: Self.cardCornerRadius
                )
            }
            .padding(.horizontal, 16)
        }
        .onEndBounce(
            axis: .horizontal,
            isEnabled: !section.items.isEmpty,
            progress: $endBounceProgress
        ) {
            onOpenCategoryDetail()
        }
    }

    private var endBounceTitle: String {
        if let name = section.genre.name, !name.isEmpty {
            return "完整\(name)"
        }
        return "完整分類"
    }

    private var contentSkeletonView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Self.cardSpacing) {
                ForEach(0..<skeletonItemCount, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: Self.cardCornerRadius, style: .continuous)
                        .fill(Color(.systemGray5))
                        .frame(width: Self.cardWidth, height: Self.cardHeight)
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

// MARK: - Preview

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
        favoriteIDs: [],
        skeletonItemCount: 5,
        onOpenCategoryDetail: {}
    )
}
