//
//  GenreMangaPosterCardView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/10.
//

import SwiftUI

struct GenreMangaPosterCardView: View {
    let item: MangaListRandomDTO
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let cardCornerRadius: CGFloat
    let isFavorite: Bool

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
                MyListCollectionStatusBadgeView(isFavorite: isFavorite)
                    .padding(8)
            }
            .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
