//
//  TrendingAnimeImageView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import SwiftUI
import SDWebImageSwiftUI

struct TrendingAnimeImageView: View {
    let url: URL

    private static let posterAspectRatio: CGFloat = 2.0 / 3.0

    @State private var didFail = false

    var body: some View {
        WebImage(url: url) { image in
            image
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(Self.posterAspectRatio, contentMode: .fill)
                .clipped()
        } placeholder: {
            Color(.systemBackground)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(Self.posterAspectRatio, contentMode: .fill)
                .clipped()
        }
        .onFailure { _ in
            didFail = true
        }
        .overlay {
            if didFail {
                Color(.systemBackground)
                    .overlay(Image(systemName: "photo").imageScale(.large))
            }
        }
        .onChange(of: url) { _, _ in
            didFail = false
        }
    }
}

