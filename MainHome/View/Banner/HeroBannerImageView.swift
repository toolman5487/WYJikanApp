//
//  HeroBannerImageView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import SwiftUI
import SDWebImageSwiftUI

struct HeroBannerImageView: View {

    // MARK: - Properties

    let url: URL

    @State private var didFail = false

    // MARK: - Body

    var body: some View {
        WebImage(url: url) { image in
            image
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } placeholder: {
            Color(.systemBackground)
                .overlay(ProgressView())
        }
        .onFailure { _ in
            Task { @MainActor in
                didFail = true
            }
        }
        .overlay {
            if didFail {
                Color(.systemBackground)
                    .overlay(Image(systemName: "photo").imageScale(.large))
            }
        }
        .onChange(of: url) { _, _ in
            Task { @MainActor in
                didFail = false
            }
        }
    }
}

#Preview {
    HeroBannerImageView(url: URL(string: "https://example.com/image.jpg")!)
}
