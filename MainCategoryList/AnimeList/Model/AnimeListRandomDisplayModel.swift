//
//  AnimeListRandomDisplayModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/9.
//

import Foundation

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
