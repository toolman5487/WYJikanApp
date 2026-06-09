//
//  MangaDetailModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/1.
//

import Foundation

// MARK: - Response (Jikan /manga/{id})

nonisolated struct MangaDetailResponse: Codable, Sendable {
    let data: MangaDetailDTO
}

// MARK: - Manga detail

nonisolated struct MangaDetailDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let approved: Bool?
    let titles: [AnimeTitleEntryDTO]?
    let title: String?
    let titleEnglish: String?
    let titleJapanese: String?
    let titleSynonyms: [String]?
    let type: String?
    let chapters: Int?
    let volumes: Int?
    let status: String?
    let publishing: Bool?
    let published: AnimeAiredDTO?
    let score: Double?
    let scored: Double?
    let scoredBy: Int?
    let rank: Int?
    let popularity: Int?
    let members: Int?
    let favorites: Int?
    let synopsis: String?
    let background: String?
    let authors: [AnimeRelatedEntityDTO]?
    let serializations: [AnimeRelatedEntityDTO]?
    let genres: [AnimeRelatedEntityDTO]?
    let explicitGenres: [AnimeRelatedEntityDTO]?
    let themes: [AnimeRelatedEntityDTO]?
    let demographics: [AnimeRelatedEntityDTO]?

    var id: Int { malId }
}

// MARK: - Pictures

nonisolated struct MangaPicturesResponse: Codable, Sendable {
    let data: [AnimeImagesDTO]
}

nonisolated struct MangaDetailPictureItem: Identifiable, Hashable, Sendable {
    let id: Int
    let url: URL
}

nonisolated enum MangaDetailPictureMapping {

    static func items(from response: MangaPicturesResponse) -> [MangaDetailPictureItem] {
        response.data.enumerated().compactMap { index, images in
            guard let url = bestURL(from: images) else { return nil }
            return MangaDetailPictureItem(id: index, url: url)
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
            guard let raw = candidate?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !raw.isEmpty,
                  let url = URL(string: raw) else {
                continue
            }
            return url
        }
        return nil
    }
}

// MARK: - Characters

nonisolated struct MangaCharactersResponse: Codable, Sendable {
    let data: [MangaCharacterRoleDTO]
}

nonisolated struct MangaCharacterRoleDTO: Codable, Identifiable, Hashable, Sendable {
    let role: String?
    let favorites: Int?
    let character: AnimeCharacterEntryDTO?

    var id: Int { character?.malId ?? role.hashValue }
}

// MARK: - Recommendations

nonisolated struct MangaRecommendationsResponse: Codable, Sendable {
    let data: [MangaRecommendationDTO]
}

nonisolated struct MangaRecommendationDTO: Codable, Identifiable, Hashable, Sendable {
    let entry: MangaRecommendationEntryDTO?
    let content: String?
    let votes: Int?

    var id: Int { entry?.malId ?? content.hashValue }
}

nonisolated struct MangaRecommendationEntryDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let title: String?
    let titleEnglish: String?
    let titleJapanese: String?

    var id: Int { malId }
}
