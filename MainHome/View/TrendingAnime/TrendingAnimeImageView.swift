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

    @State private var didFail = false

    var body: some View {
        WebImage(url: url) { image in
            image
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } placeholder: {
            Color(.systemBackground)
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

