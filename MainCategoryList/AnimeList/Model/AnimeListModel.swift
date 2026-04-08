//
//  AnimeListModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import Foundation

// MARK: - Random Anime Response

struct AnimeListRandomResponse: Codable {
    let data: AnimeListRandomDTO
}

// MARK: - Random Anime Item

struct AnimeListRandomDTO: Codable, Identifiable, Hashable {
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
    let episodes: Int?
    let images: AnimeListImagesDTO?
    let genres: [AnimeListGenreDTO]?

    var id: Int { malId }
}

// MARK: - Images

struct AnimeListImagesDTO: Codable, Hashable {
    let jpg: AnimeListImageURLDTO?
    let webp: AnimeListImageURLDTO?
}

struct AnimeListImageURLDTO: Codable, Hashable {
    let imageUrl: String?
    let smallImageUrl: String?
    let largeImageUrl: String?
}

// MARK: - Genre

struct AnimeListGenreDTO: Codable, Identifiable, Hashable {
    let malId: Int
    let name: String?

    var id: Int { malId }
}

// MARK: - Display

extension AnimeListRandomDTO {
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
        for s in candidates {
            if let s, let url = URL(string: s) { return url }
        }
        return nil
    }

    var synopsisPreview: String? {
        guard let synopsis else { return nil }
        let trimmed = synopsis.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let limit = 160
        if trimmed.count <= limit { return trimmed }
        let idx = trimmed.index(trimmed.startIndex, offsetBy: limit)
        return String(trimmed[..<idx]) + "…"
    }
}
