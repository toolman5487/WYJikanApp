//
//  RemotePosterImageView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import SwiftUI
import SDWebImageSwiftUI

// MARK: - RemotePosterImageView

struct RemotePosterImageView: View {

    // MARK: - Properties

    let url: URL
    let contentMode: ContentMode
    let fixedSize: CGSize?
    let onImageSizeChange: ((CGSize) -> Void)?

    @Environment(\.displayScale) private var displayScale
    @State private var didFail = false

    // MARK: - Lifecycle

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

    // MARK: - Body

    var body: some View {
        WebImage(
            url: url,
            options: imageOptions,
            context: imageContext
        ) { image in
            configuredImage(image)
        } placeholder: {
            Color(.systemBackground)
        }
        .onFailure { _ in
            setDidFail(true)
        }
        .onSuccess { image, _, _ in
            setDidFail(false)
            notifyImageSizeChange(image.size)
        }
        .overlay {
            if didFail {
                failurePlaceholder
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .onChange(of: url) { _, _ in
            setDidFail(false)
        }
    }

    // MARK: - Private Views

    private var failurePlaceholder: some View {
        Color(.systemBackground)
            .overlay {
                Image(systemName: "photo")
                    .imageScale(.large)
            }
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

    // MARK: - Private Methods

    private func setDidFail(_ value: Bool) {
        guard !Thread.isMainThread else {
            didFail = value
            return
        }

        Task { @MainActor in
            didFail = value
        }
    }

    private func notifyImageSizeChange(_ size: CGSize) {
        guard let onImageSizeChange else { return }

        guard !Thread.isMainThread else {
            onImageSizeChange(size)
            return
        }

        Task { @MainActor in
            onImageSizeChange(size)
        }
    }

    // MARK: - SDWebImage Configuration

    private var imageOptions: SDWebImageOptions {
        [.retryFailed, .scaleDownLargeImages]
    }

    private var imageContext: [SDWebImageContextOption: Any]? {
        guard let fixedSize, !usesWebPImage else { return nil }

        return [
            .imageThumbnailPixelSize: CGSize(
                width: fixedSize.width * displayScale,
                height: fixedSize.height * displayScale
            )
        ]
    }

    private var usesWebPImage: Bool {
        url.pathExtension.localizedCaseInsensitiveCompare("webp") == .orderedSame
    }
}
