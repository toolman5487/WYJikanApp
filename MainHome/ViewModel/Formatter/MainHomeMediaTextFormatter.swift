//
//  MainHomeMediaTextFormatter.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/15.
//

import Foundation

nonisolated struct MainHomeMediaTextFormatter: Sendable {
    func preferredTitle(
        japanese: String?,
        english: String?,
        fallback: String?,
        defaultTitle: String = "未命名作品"
    ) -> String {
        DisplayTextFormatting.preferred(
            [japanese, english, fallback],
            fallback: defaultTitle
        )
    }

    func normalizedText(_ value: String?) -> String? {
        DisplayTextFormatting.nonEmpty(value)
    }

    func animeTypeText(_ raw: String?) -> String? {
        MediaTypeFormatting.localizedName(for: raw, kind: .anime)
    }

    func scoreText(_ score: Double?, precision: Int) -> String? {
        guard let score else { return nil }
        return DisplayNumberFormatting.fixed(score, fractionDigits: precision)
    }

    func episodeText(_ episodes: Int?) -> String? {
        episodes.map { "\($0) 集" }
    }

    func popularityText(_ popularity: Int?) -> String? {
        popularity.map { "人氣 #\($0)" }
    }

    func memberCountText(_ members: Int?) -> String? {
        guard let members else { return nil }
        let count = DisplayNumberFormatting.compact(
            members,
            locale: Locale(identifier: "en_US_POSIX")
        )
        return "\(count) 收藏"
    }

    func animeStatusText(_ raw: String?) -> String? {
        guard let raw = normalizedText(raw) else { return nil }

        switch raw.lowercased() {
        case "currently airing": return "播出中"
        case "finished airing": return "已完結"
        case "not yet aired": return "尚未播出"
        default: return raw
        }
    }

    func animeSeasonText(season: String?, year: Int?) -> String? {
        let seasonText: String?

        switch season?.lowercased() {
        case "winter": seasonText = "冬"
        case "spring": seasonText = "春"
        case "summer": seasonText = "夏"
        case "fall": seasonText = "秋"
        default: seasonText = nil
        }

        switch (seasonText, year) {
        case let (seasonText?, year?):
            return "\(year) \(seasonText)季"
        case let (seasonText?, nil):
            return seasonText
        case let (nil, year?):
            return "\(year)"
        case (nil, nil):
            return nil
        }
    }

    func studioText(_ studios: [AnimeRelatedEntityDTO]?, limit: Int = 2) -> String? {
        let names = (studios ?? []).compactMap { studio in
            normalizedText(studio.name)
        }
        guard !names.isEmpty else { return nil }
        return names.prefix(limit).joined(separator: "、")
    }

    func synopsisPreview(_ synopsis: String?, limit: Int) -> String? {
        guard let trimmedSynopsis = normalizedText(synopsis) else { return nil }
        guard trimmedSynopsis.count > limit else { return trimmedSynopsis }

        let index = trimmedSynopsis.index(trimmedSynopsis.startIndex, offsetBy: limit)
        return String(trimmedSynopsis[..<index]) + "..."
    }
}
