//
//  GenreAnimePosterCardView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/9.
//

import SwiftUI

struct GenreAnimePosterCardView: View {
    let item: AnimeListRandomDTO
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let cardCornerRadius: CGFloat

    var body: some View {
        NavigationLink {
            AnimeDetailView(malId: item.id)
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
                MyListCollectionStatusBadgeView(malId: item.id, mediaKind: .anime)
                    .padding(8)
            }
            .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
