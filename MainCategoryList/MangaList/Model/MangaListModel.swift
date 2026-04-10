//
//  MangaListModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/10.
//

import Foundation

// MARK: - Genre

struct MangaListGenreDTO: Codable, Identifiable, Hashable {
    let malId: Int
    let name: String?

    var id: Int { malId }
}

struct MangaGenreSection: Identifiable, Hashable {
    let genre: MangaListGenreDTO
    let items: [MangaListRandomDTO]

    var id: Int { genre.id }
}

// MARK: - Images

struct MangaListImagesDTO: Codable, Hashable {
    let jpg: MangaListImageURLDTO?
    let webp: MangaListImageURLDTO?
}

struct MangaListImageURLDTO: Codable, Hashable {
    let imageUrl: String?
    let smallImageUrl: String?
    let largeImageUrl: String?
}

// MARK: - Item

struct MangaListRandomDTO: Codable, Identifiable, Hashable {
    let malId: Int
    let title: String?
    let titleEnglish: String?
    let titleJapanese: String?
    let synopsis: String?
    let type: String?
    let score: Double?
    let rank: Int?
    let popularity: Int?
    let members: Int?
    let chapters: Int?
    let volumes: Int?
    let images: MangaListImagesDTO?
    let genres: [MangaListGenreDTO]?

    var id: Int { malId }
}

// MARK: - Response

struct MangaGenreListResponse: Codable {
    let data: [MangaListGenreDTO]
}

struct MangaListResponse: Codable {
    let data: [MangaListRandomDTO]
}

struct MangaListRandomResponse: Codable {
    let data: MangaListRandomDTO
}

// MARK: - Display

extension MangaListRandomDTO {
    var displayTitle: String {
        if let t = titleJapanese?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty { return t }
        if let t = title?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty { return t }
        if let t = titleEnglish?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty { return t }
        return "未命名作品"
    }

    var posterURL: URL? {
        let candidates = [
            images?.webp?.largeImageUrl,
            images?.jpg?.largeImageUrl,
            images?.webp?.imageUrl,
            images?.jpg?.imageUrl,
            images?.webp?.smallImageUrl,
            images?.jpg?.smallImageUrl
        ]

        for candidate in candidates {
            if let candidate, let url = URL(string: candidate) {
                return url
            }
        }
        return nil
    }
}

// MARK: - Localization

enum MangaGenreLocalizationModel {
    static func localizedName(for englishName: String) -> String {
        AnimeGenreLocalizationModel.localizedName(for: englishName)
    }
}
