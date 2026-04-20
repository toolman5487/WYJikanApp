//
//  CharacterListModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/20.
//

import Foundation

struct CharacterListResponse: Codable, Sendable {
    let pagination: CharacterListPagination?
    let data: [CharacterListDTO]
}

struct CharacterListPagination: Codable, Hashable, Sendable {
    let currentPage: Int?
    let hasNextPage: Bool?
    let lastVisiblePage: Int?
}

struct CharacterListDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let name: String?
    let nameKanji: String?
    let nicknames: [String]?

    var id: Int { malId }
}

struct CharacterListRow: Identifiable, Hashable, Sendable {
    let id: Int
    let malId: Int
    let name: String
    let imageURL: URL?
    let malPageURL: URL?

    static func from(_ dto: CharacterListDTO) -> CharacterListRow {
        CharacterListRow(
            id: dto.malId,
            malId: dto.malId,
            name: displayName(japanese: dto.nameKanji, fallback: dto.name),
            imageURL: posterURL(from: dto.images),
            malPageURL: malPageURL(from: dto.url, malId: dto.malId)
        )
    }

    private static func displayName(japanese: String?, fallback: String?) -> String {
        let candidates = [japanese, fallback]
        for candidate in candidates {
            if let text = candidate?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
                return text
            }
        }
        return "—"
    }

    private static func malPageURL(from urlString: String?, malId: Int) -> URL? {
        if let urlString, let url = URL(string: urlString) {
            return url
        }
        return URL(string: "https://myanimelist.net/character/\(malId)")
    }

    private static func posterURL(from images: AnimeImagesDTO?) -> URL? {
        let webp = images?.webp
        let jpg = images?.jpg
        let candidates: [String?] = [
            webp?.largeImageUrl,
            jpg?.largeImageUrl,
            webp?.imageUrl,
            jpg?.imageUrl,
            jpg?.smallImageUrl,
            webp?.smallImageUrl
        ]
        return candidates.compactMap { $0 }.first.flatMap { URL(string: $0) }
    }
}
