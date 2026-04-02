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

    func malWorkPageURL(for anime: AnimeDetailDTO) -> URL? {
        if let raw = anime.url?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty,
           let url = URL(string: raw) {
            return url
        }
        return URL(string: "https://myanimelist.net/anime/\(anime.malId)")
    }

    func hasSensitiveContent(for anime: AnimeDetailDTO) -> Bool {
        sensitiveContentText(for: anime) != nil
    }

    func sensitiveContentText(for anime: AnimeDetailDTO) -> String? {
        var names = (anime.explicitGenres ?? []).compactMap(\.name).filter { !$0.isEmpty }
        if names.isEmpty {
            let fallback = (anime.genres ?? [])
                .compactMap(\.name)
                .filter { name in
                    let lower = name.lowercased()
                    return lower == "hentai" || lower == "ecchi"
                }
            names = fallback
        }
        guard !names.isEmpty else { return nil }
        return "敏感內容"
    }

    // MARK: - Trailer

    func hasTrailer(for anime: AnimeDetailDTO) -> Bool {
        trailerEmbedURL(for: anime) != nil
    }

    func trailerEmbedURL(for anime: AnimeDetailDTO) -> URL? {
        guard let trailer = anime.trailer else { return nil }
        if let id = resolvedYouTubeVideoId(from: trailer),
           var components = URLComponents(string: "https://www.youtube.com/embed/\(id)") {
            components.queryItems = [
                URLQueryItem(name: "playsinline", value: "1"),
                URLQueryItem(name: "rel", value: "0"),
                URLQueryItem(name: "modestbranding", value: "1"),
                URLQueryItem(name: "autoplay", value: "0")
            ]
            if let url = components.url {
                return url
            }
        }
        if let embed = trailer.embedUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
           !embed.isEmpty,
           let url = URL(string: embed) {
            return url
        }
        return nil
    }

    func trailerWatchURL(for anime: AnimeDetailDTO) -> URL? {
        guard let trailer = anime.trailer else { return nil }
        if let raw = trailer.url?.trimmingCharacters(in: .whitespacesAndNewlines),
           !raw.isEmpty,
           let url = URL(string: raw) {
            return url
        }
        guard let id = resolvedYouTubeVideoId(from: trailer) else { return nil }
        return URL(string: "https://www.youtube.com/watch?v=\(id)")
    }

    func trailerThumbnailURL(for anime: AnimeDetailDTO) -> URL? {
        guard let trailer = anime.trailer else { return nil }
        let candidates: [String?] = [
            trailer.images?.maximumImageUrl,
            trailer.images?.largeImageUrl,
            trailer.images?.mediumImageUrl,
            trailer.images?.smallImageUrl,
            trailer.images?.imageUrl
        ]
        for candidate in candidates {
            guard let s = candidate?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty,
                  let url = URL(string: s) else { continue }
            return url
        }
        guard let id = resolvedYouTubeVideoId(from: trailer) else { return nil }
        return URL(string: "https://img.youtube.com/vi/\(id)/hqdefault.jpg")
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
            let tzId = AnimeDetailDateFormatting.sourceTimeZoneIdentifier(for: broadcast)
            if let local = AnimeDetailDateFormatting.localBroadcastString(
                dayEnglish: day,
                timeHHMM: time,
                sourceTimeZoneIdentifier: tzId
            ) {
                return local
            }
            return "\(AnimeDetailDateFormatting.weekdayChinese(from: day)) \(time)"
        }
        if let string = broadcast.string?.trimmingCharacters(in: .whitespacesAndNewlines), !string.isEmpty {
            if let local = AnimeDetailDateFormatting.localBroadcastFromEnglishString(string) {
                return local
            }
            return AnimeDetailDateFormatting.translateBroadcastEnglishString(string)
        }
        return nil
    }

    func airedPeriodDisplayText(for anime: AnimeDetailDTO) -> String? {
        AnimeDetailDateFormatting.localizedPeriod(from: anime.aired)
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
        mediaKind(for: anime).displayName
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

    func hasThemes(for anime: AnimeDetailDTO) -> Bool {
        guard let themes = anime.themes, !themes.isEmpty else { return false }
        return themes.contains { theme in
            let name = theme.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return !name.isEmpty
        }
    }

    func themeDisplayItems(for anime: AnimeDetailDTO) -> [AnimeRelatedEntityDTO] {
        guard let themes = anime.themes else { return [] }
        return themes
            .filter { theme in
                let name = theme.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return !name.isEmpty
            }
            .sorted {
                ($0.name ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending
            }
    }

    func hasStaffInfo(for anime: AnimeDetailDTO) -> Bool {
        let studioText = joinedNames(from: anime.studios)
        let producerText = joinedNames(from: anime.producers)
        let genreText = joinedNames(from: anime.genres)
        return studioText != "-" || producerText != "-" || genreText != "-"
    }

    var hasPictures: Bool {
        !pictureItems.isEmpty
    }

    // MARK: - Private Methods

    private func resolvedYouTubeVideoId(from trailer: AnimeDetailTrailerDTO) -> String? {
        if let embed = trailer.embedUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
           !embed.isEmpty,
           let url = URL(string: embed) {
            let path = url.path
            if let range = path.range(of: "/embed/") {
                let rest = String(path[range.upperBound...])
                let segment = rest.split(separator: "/").first.map(String.init) ?? String(rest)
                let withoutQuery = segment.split(separator: "?").first.map(String.init) ?? segment
                if !withoutQuery.isEmpty { return withoutQuery }
            }
        }
        if let id = trailer.youtubeId?.trimmingCharacters(in: .whitespacesAndNewlines), !id.isEmpty {
            return id
        }
        if let watch = trailer.url,
           let url = URL(string: watch),
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            return components.queryItems?.first(where: { $0.name == "v" })?.value
        }
        return nil
    }

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
        synopsis = synopsis.replacingOccurrences(
            of: "\n\n(Source: MAL News)",
            with: "",
            options: .caseInsensitive
        )
        synopsis = synopsis.replacingOccurrences(
            of: "\n(Source: MAL News)",
            with: "",
            options: .caseInsensitive
        )
        synopsis = synopsis.replacingOccurrences(
            of: "(Source: MAL News)",
            with: "",
            options: .caseInsensitive
        )
        let trimmed = synopsis.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
