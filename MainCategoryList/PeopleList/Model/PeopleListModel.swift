//
//  PeopleListModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/20.
//

import Foundation

struct PeopleListResponse: Codable, Sendable {
    let pagination: PeopleListPagination?
    let data: [PeopleListDTO]
}

struct PeopleListPagination: Codable, Hashable, Sendable {
    let currentPage: Int?
    let hasNextPage: Bool?
    let lastVisiblePage: Int?
}

struct PeopleListDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let name: String?
    let givenName: String?
    let familyName: String?

    var id: Int { malId }
}

struct PeopleListRow: Identifiable, Hashable, Sendable {
    let id: Int
    let malId: Int
    let name: String
    let imageURL: URL?
    let malPageURL: URL?

    static func from(_ dto: PeopleListDTO) -> PeopleListRow {
        PeopleListRow(
            id: dto.malId,
            malId: dto.malId,
            name: displayName(familyName: dto.familyName, givenName: dto.givenName, fallback: dto.name),
            imageURL: posterURL(from: dto.images),
            malPageURL: malPageURL(from: dto.url, malId: dto.malId)
        )
    }

    private static func displayName(familyName: String?, givenName: String?, fallback: String?) -> String {
        let familyName = familyName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let givenName = givenName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let japaneseName = [familyName, givenName]
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        let candidates = [japaneseName, fallback]
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
        return URL(string: "https://myanimelist.net/people/\(malId)")
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
