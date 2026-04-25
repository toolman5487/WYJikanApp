//
//  GenreMangaViews.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/10.
//

import SwiftUI

struct GenreMangaListContainerView: View {
    @ObservedObject var viewModel: GenreMangaViewModel

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.genreSections.isEmpty {
                GenreMangaListSkeletonView()
            } else {
                if let message = viewModel.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }

                ForEach(viewModel.genreSections) { section in
                    GenreMangaSectionView(section: section)
                }

                if viewModel.canLoadMore {
                    Button {
                        viewModel.loadMoreSections()
                    } label: {
                        if viewModel.isLoadingMore {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 44)
                        } else {
                            Text("載入更多種類")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(ThemeColor.sakura)
                    .disabled(viewModel.isLoadingMore)
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

private struct GenreMangaSectionView: View {
    private static let cardHeight: CGFloat = 200
    private static let posterAspectRatio: CGFloat = 2.0 / 3.0
    private static let cardCornerRadius: CGFloat = 16
    private static let cardSpacing: CGFloat = 12
    private static let horizontalPadding: CGFloat = 16

    let section: MangaGenreSection

    private static var cardWidth: CGFloat {
        cardHeight * posterAspectRatio
    }

    private var titleText: String {
        section.genre.name ?? "未分類"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(titleText)
                .font(.title3.weight(.bold))
                .foregroundStyle(ThemeColor.sakura)

            if section.items.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Self.cardSpacing) {
                        ForEach(0..<6, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: Self.cardCornerRadius, style: .continuous)
                                .fill(Color(.systemGray5))
                                .frame(width: Self.cardWidth, height: Self.cardHeight)
                        }
                    }
                    .padding(.horizontal, Self.horizontalPadding)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Self.cardSpacing) {
                        ForEach(section.items.prefix(10)) { item in
                            GenreMangaPosterCardView(
                                item: item,
                                cardWidth: Self.cardWidth,
                                cardHeight: Self.cardHeight,
                                cardCornerRadius: Self.cardCornerRadius
                            )
                        }
                    }
                    .padding(.horizontal, Self.horizontalPadding)
                }
            }
        }
    }
}

private struct GenreMangaPosterCardView: View {
    let item: MangaListRandomDTO
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let cardCornerRadius: CGFloat

    var body: some View {
        NavigationLink {
            MangaDetailView(malId: item.id)
        } label: {
            PosterCardView(rank: item.rank) {
                Group {
                    if let posterURL = item.posterURL {
                        RemotePosterImageView(url: posterURL)
                    } else {
                        Color(.secondarySystemFill)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
            }
            .frame(width: cardWidth, height: cardHeight)
            .overlay(alignment: .topTrailing) {
                MyListCollectionStatusBadgeView(malId: item.id, mediaKind: .manga)
                    .padding(8)
            }
            .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct GenreMangaListSkeletonView: View {
    private static let cardCount = 6
    private static let cardHeight: CGFloat = 240
    private static let posterAspectRatio: CGFloat = 2.0 / 3.0
    private static let cardCornerRadius: CGFloat = 16
    private static let cardSpacing: CGFloat = 12
    private static let horizontalPadding: CGFloat = 16
    private static let sectionCount = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(0..<Self.sectionCount, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 10) {
                    SkeletonBar(width: 120, height: 24, cornerRadius: 8)
                        .padding(.horizontal, Self.horizontalPadding)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Self.cardSpacing) {
                            ForEach(0..<Self.cardCount, id: \.self) { _ in
                                RoundedRectangle(
                                    cornerRadius: Self.cardCornerRadius,
                                    style: .continuous
                                )
                                .fill(Color(.systemGray5))
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: Self.cardCornerRadius,
                                        style: .continuous
                                    )
                                )
                                .frame(
                                    width: Self.cardHeight * Self.posterAspectRatio,
                                    height: Self.cardHeight
                                )
                            }
                        }
                        .padding(.horizontal, Self.horizontalPadding)
                    }
                }
            }
        }
    }
}
