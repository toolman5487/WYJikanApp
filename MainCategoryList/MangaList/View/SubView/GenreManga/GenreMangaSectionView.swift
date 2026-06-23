//
//  GenreMangaSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/10.
//

import SwiftUI

struct GenreMangaSectionView: View {

    // MARK: - Constants

    private static let cardHeight: CGFloat = 200
    private static let posterAspectRatio: CGFloat = 2.0 / 3.0
    private static let cardCornerRadius: CGFloat = 16
    private static let cardSpacing: CGFloat = 12

    // MARK: - Properties

    let section: MangaGenreSection
    let favoriteIDs: Set<Int>
    let skeletonItemCount: Int
    let onOpenCategoryDetail: () -> Void

    @State private var endBounceProgress: CGFloat = 0

    private static var cardWidth: CGFloat {
        cardHeight * posterAspectRatio
    }

    // MARK: - Body

    var body: some View {
        Group {
            if section.items.isEmpty {
                contentSkeletonView
            } else {
                contentView
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: - Private Methods

    private var contentView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Self.cardSpacing) {
                ForEach(section.items.prefix(10)) { item in
                    GenreMangaPosterCardView(
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

// MARK: - GenreMangaSectionHeaderView

struct GenreMangaSectionHeaderView: View {

    // MARK: - Properties

    let section: MangaGenreSection
    let onSelectGenre: (MangaListGenreDTO) -> Void

    // MARK: - Body

    var body: some View {
        Button {
            onSelectGenre(section.genre)
        } label: {
            GlassSectionHeaderView(
                title: titleText,
                showsDisclosureIndicator: true,
                outerVerticalPadding: 0
            )
            .padding(.top, 4)
            .padding(.bottom, 10)
        }
        .buttonStyle(.plain)
        .background(Color(.systemBackground).opacity(0.001))
    }

    // MARK: - Private Methods

    private var titleText: String {
        section.genre.name ?? "未分類"
    }
}
