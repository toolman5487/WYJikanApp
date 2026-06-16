//
//  MangaDetailImagePreviewBuilder.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/2.
//

import Foundation

// MARK: - MangaDetailImagePreviewBuilder

struct MangaDetailImagePreviewBuilder {

    // MARK: - Public Methods

    func items(
        mangaId: Int,
        posterURL: URL?,
        pictureItems: [MangaDetailPictureItem]
    ) -> [ImagePreviewItem] {
        var items: [ImagePreviewItem] = []
        var seenURLs = Set<URL>()

        if let posterURL, seenURLs.insert(posterURL).inserted {
            items.append(ImagePreviewItem(id: "poster-\(mangaId)", url: posterURL))
        }

        for picture in pictureItems where seenURLs.insert(picture.url).inserted {
            items.append(ImagePreviewItem(id: "picture-\(picture.id)", url: picture.url))
        }

        return items
    }

    func initialIndex(
        for items: [ImagePreviewItem],
        selectedImageURL: URL?
    ) -> Int {
        guard !items.isEmpty else { return 0 }
        guard let selectedImageURL,
              let index = items.firstIndex(where: { $0.url == selectedImageURL }) else {
            return 0
        }
        return index
    }

    func initialIndex(
        for items: [ImagePreviewItem],
        selectedPictureIndex: Int,
        hasPoster: Bool
    ) -> Int {
        guard !items.isEmpty else { return 0 }
        let posterOffset = hasPoster ? 1 : 0
        return min(selectedPictureIndex + posterOffset, max(items.count - 1, 0))
    }
}
