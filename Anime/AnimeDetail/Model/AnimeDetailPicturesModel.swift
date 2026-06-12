//
//  AnimeDetailPicturesModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

import Foundation

// MARK: - Response

nonisolated struct AnimePicturesResponse: Codable, Sendable {
    let data: [AnimeImagesDTO]
}

// MARK: - Presentation

nonisolated struct AnimeDetailPictureItem: Identifiable, Hashable, Sendable {
    let id: Int
    let url: URL
}

nonisolated enum AnimeDetailPictureMapping {

    static func items(from response: AnimePicturesResponse) -> [AnimeDetailPictureItem] {
        response.data.enumerated().compactMap { index, images in
            guard let url = bestURL(from: images) else { return nil }
            return AnimeDetailPictureItem(id: index, url: url)
        }
    }

    private static func bestURL(from images: AnimeImagesDTO) -> URL? {
        JikanImageURLResolver.url(from: images, tier: .full)
    }
}
