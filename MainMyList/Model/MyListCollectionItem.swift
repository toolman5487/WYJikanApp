//
//  MyListCollectionItem.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import Foundation
import SwiftData

enum MyListMediaKind: String, Codable, CaseIterable, Identifiable {
    case anime
    case manga

    var id: String { rawValue }

    var title: String {
        switch self {
        case .anime: return "動畫"
        case .manga: return "漫畫"
        }
    }

    var iconName: String {
        switch self {
        case .anime: return "play.rectangle.fill"
        case .manga: return "book.closed.fill"
        }
    }
}

@Model
final class MyListCollectionItem {
    var malId: Int
    var mediaKindRawValue: String
    var title: String
    var subtitle: String?
    var imageURLString: String?
    var genreNamesRawValue: String?
    var type: String?
    var year: Int?
    var addedAt: Date

    init(
        malId: Int,
        mediaKind: MyListMediaKind,
        title: String,
        subtitle: String?,
        imageURLString: String?,
        genreNames: [String] = [],
        type: String? = nil,
        year: Int? = nil,
        addedAt: Date
    ) {
        self.malId = malId
        self.mediaKindRawValue = mediaKind.rawValue
        self.title = title
        self.subtitle = subtitle
        self.imageURLString = imageURLString
        self.genreNamesRawValue = Self.serializeGenreNames(genreNames)
        self.type = Self.normalizedText(type)
        self.year = year
        self.addedAt = addedAt
    }
}

extension MyListCollectionItem {
    var mediaKind: MyListMediaKind {
        MyListMediaKind(rawValue: mediaKindRawValue) ?? .anime
    }

    var imageURL: URL? {
        guard let imageURLString else { return nil }
        return URL(string: imageURLString)
    }

    var genreNames: [String] {
        guard
            let genreNamesRawValue,
            let data = genreNamesRawValue.data(using: .utf8),
            let decodedGenreNames = try? JSONDecoder().decode([String].self, from: data)
        else {
            return []
        }

        return Self.normalizedGenreNames(from: decodedGenreNames)
    }

    private static func serializeGenreNames(_ genreNames: [String]) -> String? {
        let normalizedGenreNames = normalizedGenreNames(from: genreNames)
        guard
            !normalizedGenreNames.isEmpty,
            let data = try? JSONEncoder().encode(normalizedGenreNames)
        else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    private static func normalizedText(_ text: String?) -> String? {
        guard let text else { return nil }
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedText.isEmpty ? nil : trimmedText
    }

    private static func normalizedGenreNames(from genreNames: [String]) -> [String] {
        var seenGenreNames = Set<String>()
        var normalizedGenreNames: [String] = []

        for genreName in genreNames {
            let trimmedGenreName = genreName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedGenreName.isEmpty else { continue }
            guard seenGenreNames.insert(trimmedGenreName).inserted else { continue }
            normalizedGenreNames.append(trimmedGenreName)
        }

        return normalizedGenreNames
    }
}
