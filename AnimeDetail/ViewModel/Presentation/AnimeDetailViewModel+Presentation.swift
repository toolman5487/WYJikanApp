//
//  AnimeDetailViewModel+Presentation.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import Foundation

extension AnimeDetailViewModel {

    // MARK: - Header & Media

    func displayTitle(for anime: AnimeDetailDTO) -> String {
        anime.titleJapanese ?? anime.titleEnglish ?? anime.title ?? "🎬"
    }

    func posterURL(for anime: AnimeDetailDTO) -> URL? {
        let urlString =
            anime.images?.webp?.largeImageUrl ??
            anime.images?.jpg?.largeImageUrl ??
            anime.images?.webp?.imageUrl ??
            anime.images?.jpg?.imageUrl
        guard let urlString else { return nil }
        return URL(string: urlString)
    }

    // MARK: - Basic Info

    func airingDisplayText(for anime: AnimeDetailDTO) -> String {
        guard let airing = anime.airing else { return "-" }
        return airing ? "連載中" : "結束連載"
    }

    func durationDisplayText(for anime: AnimeDetailDTO) -> String {
        guard let raw = anime.duration?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return "-"
        }
        let lower = raw.lowercased()
        if lower == "unknown" {
            return "未知"
        }
        var result = raw
        result = result.replacingOccurrences(of: "min per episode", with: "分鐘／集", options: .caseInsensitive)
        result = result.replacingOccurrences(of: "min per ep", with: "分鐘／集", options: .caseInsensitive)
        result = result.replacingOccurrences(of: "minutes", with: "分鐘", options: .caseInsensitive)
        result = result.replacingOccurrences(of: "minute", with: "分鐘", options: .caseInsensitive)
        result = result.replacingOccurrences(of: "hours", with: "小時", options: .caseInsensitive)
        result = result.replacingOccurrences(of: "hour", with: "小時", options: .caseInsensitive)
        result = result.replacingOccurrences(of: "hrs", with: "小時", options: .caseInsensitive)
        result = result.replacingOccurrences(of: " hr", with: " 小時", options: .caseInsensitive)
        result = result.replacingOccurrences(of: " mins", with: " 分鐘", options: .caseInsensitive)
        result = result.replacingOccurrences(of: " min", with: " 分鐘", options: .caseInsensitive)
        return result.replacingOccurrences(of: "  ", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func weeklyBroadcastScheduleText(for anime: AnimeDetailDTO) -> String? {
        guard let broadcast = anime.broadcast else { return nil }
        let day = broadcast.day?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let time = broadcast.time?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !day.isEmpty, !time.isEmpty {
            let tzId = AnimeDetailBroadcastFormatting.sourceTimeZoneIdentifier(for: broadcast)
            if let local = AnimeDetailBroadcastFormatting.localBroadcastString(
                dayEnglish: day,
                timeHHMM: time,
                sourceTimeZoneIdentifier: tzId
            ) {
                return local
            }
            return "\(AnimeDetailBroadcastFormatting.weekdayChinese(from: day)) \(time)"
        }
        if let string = broadcast.string?.trimmingCharacters(in: .whitespacesAndNewlines), !string.isEmpty {
            if let local = AnimeDetailBroadcastFormatting.localBroadcastFromEnglishString(string) {
                return local
            }
            return AnimeDetailBroadcastFormatting.translateBroadcastEnglishString(string)
        }
        return nil
    }

    func airedPeriodDisplayText(for anime: AnimeDetailDTO) -> String? {
        guard let airedString = anime.aired?.string?.trimmingCharacters(in: .whitespacesAndNewlines),
              !airedString.isEmpty else { return nil }
        return airedString
    }

    func broadcastDisplayText(for anime: AnimeDetailDTO) -> String {
        if let weekly = weeklyBroadcastScheduleText(for: anime) {
            return weekly
        }
        if let aired = airedPeriodDisplayText(for: anime) {
            return aired
        }
        return "-"
    }

    func seasonInfoRowTitle(for anime: AnimeDetailDTO) -> String {
        let season = seasonText(for: anime)
        if season != "-" { return "播出季度" }
        if airedPeriodDisplayText(for: anime) != nil { return "播出期間" }
        return "播出季度"
    }

    func seasonBlockPrimaryText(for anime: AnimeDetailDTO) -> String {
        let season = seasonText(for: anime)
        if season != "-" { return season }
        if let aired = airedPeriodDisplayText(for: anime) { return aired }
        return "-"
    }

    func seasonBlockSubtitle(for anime: AnimeDetailDTO) -> String? {
        let season = seasonText(for: anime)
        guard season != "-" else { return nil }
        guard weeklyBroadcastScheduleText(for: anime) == nil else { return nil }
        return airedPeriodDisplayText(for: anime)
    }

    func seasonText(for anime: AnimeDetailDTO) -> String {
        let seasonLabel = AnimeDetailSeasonFormatting.chineseLabel(from: anime.season)
        let yearString = anime.year.map(String.init)

        switch (seasonLabel, yearString) {
        case let (s?, y?):
            return "\(y) \(s)"
        case let (s?, nil):
            return s
        case let (nil, y?):
            return y
        default:
            return "-"
        }
    }

    func typeDisplayText(for anime: AnimeDetailDTO) -> String {
        guard let raw = anime.type?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return "-"
        }
        switch raw.uppercased() {
        case "TV": return "電視動畫"
        case "MOVIE": return "劇場版"
        case "OVA": return "OVA"
        case "ONA": return "網路動畫"
        case "SPECIAL": return "特別篇"
        case "MUSIC": return "音樂"
        default: return raw
        }
    }

    func statusDisplayText(for anime: AnimeDetailDTO) -> String {
        guard let raw = anime.status?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return "-"
        }
        let lower = raw.lowercased()
        if lower == "finished airing" { return "已完結" }
        if lower == "currently airing" { return "播出中" }
        if lower == "not yet aired" { return "尚未播出" }
        return raw
    }

    func sourceDisplayText(for anime: AnimeDetailDTO) -> String {
        guard let raw = anime.source?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return "-"
        }
        let lower = raw.lowercased()
        if lower == "manga" { return "漫畫改編" }
        if lower == "light novel" { return "輕小說改編" }
        if lower == "novel" { return "小說改編" }
        if lower == "original" { return "原創" }
        if lower == "visual novel" { return "視覺小說改編" }
        if lower == "web manga" { return "網路漫畫改編" }
        if lower == "other" { return "其他" }
        return raw
    }

    func ratingDisplayText(for anime: AnimeDetailDTO) -> String {
        guard let raw = anime.rating?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return "-"
        }
        if raw.hasPrefix("G -") { return "普遍級" }
        if raw.hasPrefix("PG -") { return "保護級" }
        if raw.hasPrefix("PG-13 -") { return "輔導 13+" }
        if raw.hasPrefix("R - 17+") { return "限制級 17+" }
        if raw.hasPrefix("R+ -") { return "限制級+" }
        if raw.hasPrefix("Rx -") { return "成人級" }
        return raw
    }

    // MARK: - Lists & Numbers

    func joinedNames(from entities: [AnimeRelatedEntityDTO]?) -> String {
        guard let entities, !entities.isEmpty else { return "-" }
        let names = entities.compactMap(\.name).filter { !$0.isEmpty }
        return names.isEmpty ? "-" : names.joined(separator: "、")
    }

    func formatNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    // MARK: - Score & Visibility

    func scoreDisplayText(for anime: AnimeDetailDTO) -> String {
        guard let score = anime.score else { return "-" }
        return String(format: "%.2f", score) + " / 10.0"
    }

    func synopsisDisplayText(for anime: AnimeDetailDTO) -> String {
        cleanedSynopsis(for: anime) ?? "-"
    }

    func hasSynopsis(for anime: AnimeDetailDTO) -> Bool {
        guard let synopsis = cleanedSynopsis(for: anime) else { return false }
        return !synopsis.isEmpty
    }

    func hasStaffInfo(for anime: AnimeDetailDTO) -> Bool {
        let studioText = joinedNames(from: anime.studios)
        let producerText = joinedNames(from: anime.producers)
        let genreText = joinedNames(from: anime.genres)
        return studioText != "-" || producerText != "-" || genreText != "-"
    }

    // MARK: - Private Methods

    private func cleanedSynopsis(for anime: AnimeDetailDTO) -> String? {
        guard var synopsis = anime.synopsis?.trimmingCharacters(in: .whitespacesAndNewlines), !synopsis.isEmpty else {
            return nil
        }
        synopsis = synopsis.replacingOccurrences(
            of: "\n\n[Written by MAL Rewrite]",
            with: "",
            options: .caseInsensitive
        )
        synopsis = synopsis.replacingOccurrences(
            of: "[Written by MAL Rewrite]",
            with: "",
            options: .caseInsensitive
        )
        let trimmed = synopsis.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
