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
    let fixedSize: CGSize?
    let onImageSizeChange: ((CGSize) -> Void)?

    @Environment(\.displayScale) private var displayScale
    @State private var didFail = false

    init(
        url: URL,
        contentMode: ContentMode = .fill,
        fixedSize: CGSize? = nil,
        onImageSizeChange: ((CGSize) -> Void)? = nil
    ) {
        self.url = url
        self.contentMode = contentMode
        self.fixedSize = fixedSize
        self.onImageSizeChange = onImageSizeChange
    }

    var body: some View {
        WebImage(
            url: url,
            options: [
                .retryFailed,
                .scaleDownLargeImages
            ],
            context: imageContext
        ) { image in
            configuredImage(image)
        } placeholder: {
            Color(.systemBackground)
        }
        .onFailure { _ in
            didFail = true
        }
        .onSuccess { image, _, _ in
            didFail = false
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

    private var imageContext: [SDWebImageContextOption: Any]? {
        guard let fixedSize else { return nil }

        return [
            .imageThumbnailPixelSize: CGSize(
                width: fixedSize.width * displayScale,
                height: fixedSize.height * displayScale
            )
        ]
    }

    private func configuredImage(_ image: Image) -> some View {
        image
            .resizable()
            .aspectRatio(contentMode: contentMode)
            .frame(
                width: fixedSize?.width,
                height: fixedSize?.height
            )
            .clipped()
    }
}
