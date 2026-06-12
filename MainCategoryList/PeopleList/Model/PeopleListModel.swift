//
//  PeopleListModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/20.
//

import Foundation

nonisolated enum PeopleListSort: String, CaseIterable, Hashable, Sendable {
    case popularity
    case nameAscending
    case nameDescending

    var title: String {
        switch self {
        case .popularity:
            return "熱門"
        case .nameAscending:
            return "名稱 A-Z"
        case .nameDescending:
            return "名稱 Z-A"
        }
    }

    var systemImageName: String {
        switch self {
        case .popularity:
            return "flame.fill"
        case .nameAscending:
            return "textformat.abc"
        case .nameDescending:
            return "textformat.abc.dottedunderline"
        }
    }
}

nonisolated struct PeopleListResponse: Codable, Sendable {
    let pagination: PeopleListPagination?
    let data: [PeopleListDTO]
}

nonisolated struct PeopleListPagination: Codable, Hashable, Sendable {
    let currentPage: Int?
    let hasNextPage: Bool?
    let lastVisiblePage: Int?
}

nonisolated struct PeopleListDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let name: String?
    let givenName: String?
    let familyName: String?
    let favorites: Int?

    var id: Int { malId }
}

nonisolated struct PeopleListRow: Identifiable, Hashable, Sendable {
    let id: Int
    let malId: Int
    let name: String
    let imageURL: URL?
    let malPageURL: URL?
    let favorites: Int?
    let sortTitle: String

    static func from(_ dto: PeopleListDTO) -> PeopleListRow {
        let displayName = displayName(
            familyName: dto.familyName,
            givenName: dto.givenName,
            fallback: dto.name
        )

        return PeopleListRow(
            id: dto.malId,
            malId: dto.malId,
            name: displayName,
            imageURL: posterURL(from: dto.images),
            malPageURL: malPageURL(from: dto.url, malId: dto.malId),
            favorites: dto.favorites,
            sortTitle: normalizedSortTitle(from: displayName)
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
        JikanImageURLResolver.url(from: images, tier: .card)
    }

    private static func normalizedSortTitle(from title: String) -> String {
        title.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }
}
