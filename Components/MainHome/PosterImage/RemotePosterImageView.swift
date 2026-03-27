//
//  RemotePosterImageView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import SwiftUI
import SDWebImageSwiftUI

struct RemotePosterImageView: View {
    let url: URL

    @State private var didFail = false

    var body: some View {
        GeometryReader { proxy in
            WebImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
            } placeholder: {
                Color(.systemBackground)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
            }
            .onFailure { _ in
                didFail = true
            }
            .overlay {
                if didFail {
                    Color(.systemBackground)
                        .overlay(Image(systemName: "photo").imageScale(.large))
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: url) { _, _ in
            didFail = false
        }
    }
}
