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
    let contentMode: ContentMode
    let onImageSizeChange: ((CGSize) -> Void)?

    @State private var didFail = false

    init(
        url: URL,
        contentMode: ContentMode = .fill,
        onImageSizeChange: ((CGSize) -> Void)? = nil
    ) {
        self.url = url
        self.contentMode = contentMode
        self.onImageSizeChange = onImageSizeChange
    }

    var body: some View {
        WebImage(url: url) { image in
            image
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } placeholder: {
            Color(.systemBackground)
        }
        .onFailure { _ in
            didFail = true
        }
        .onSuccess { image, _, _ in
            onImageSizeChange?(image.size)
        }
        .overlay {
            if didFail {
                Color(.systemBackground)
                    .overlay {
                        Image(systemName: "photo")
                            .imageScale(.large)
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .onChange(of: url) { _, _ in
            didFail = false
        }
    }
}
