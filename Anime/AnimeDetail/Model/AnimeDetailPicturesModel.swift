//
//  AnimeDetailPicturesModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

import Foundation

// MARK: - Response

struct AnimePicturesResponse: Codable {
    let data: [AnimeImagesDTO]
}

// MARK: - Presentation

struct AnimeDetailPictureItem: Identifiable, Hashable, Sendable {
    let id: Int
    let url: URL
}

enum AnimeDetailPictureMapping {

    static func items(from response: AnimePicturesResponse) -> [AnimeDetailPictureItem] {
        response.data.enumerated().compactMap { index, images in
            guard let url = bestURL(from: images) else { return nil }
            return AnimeDetailPictureItem(id: index, url: url)
        }
    }

    private static func bestURL(from images: AnimeImagesDTO) -> URL? {
        let candidates: [String?] = [
            images.webp?.largeImageUrl,
            images.jpg?.largeImageUrl,
            images.webp?.imageUrl,
            images.jpg?.imageUrl,
            images.webp?.smallImageUrl,
            images.jpg?.smallImageUrl
        ]
        for candidate in candidates {
            guard let raw = candidate?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty,
                  let url = URL(string: raw)
            else { continue }
            return url
        }
        return nil
    }
}
