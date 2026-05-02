//
//  MangaDetailViewModel+Presentation.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/1.
//

import Foundation

extension MangaDetailViewModel {

    enum Section: Identifiable {
        case header
        case highlights
        case score
        case synopsis
        case publication

        var id: String {
            switch self {
            case .header: return "header"
            case .highlights: return "highlights"
            case .score: return "score"
            case .synopsis: return "synopsis"
            case .publication: return "publication"
            }
        }
    }

    enum ReviewNavigationState {
        case hidden
        case available(title: String)
    }

    // MARK: - Header & Media

    func displayTitle(for manga: MangaDetailDTO) -> String {
        manga.titleJapanese ?? manga.titleEnglish ?? manga.title ?? "📖"
    }

    func posterURL(for manga: MangaDetailDTO) -> URL? {
        let urlString =
            manga.images?.webp?.largeImageUrl ??
            manga.images?.jpg?.largeImageUrl ??
            manga.images?.webp?.imageUrl ??
            manga.images?.jpg?.imageUrl
        guard let urlString else { return nil }
        return URL(string: urlString)
    }

    func malWorkPageURL(for manga: MangaDetailDTO) -> URL? {
        if let raw = manga.url?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty,
           let url = URL(string: raw) {
            return url
        }
        return URL(string: "https://myanimelist.net/manga/\(manga.malId)")
    }

    func sensitiveContentText(for manga: MangaDetailDTO) -> String? {
        var names = (manga.explicitGenres ?? []).compactMap(\.name).filter { !$0.isEmpty }
        if names.isEmpty {
            let fallback = (manga.genres ?? [])
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

    func reviewTitle(for manga: MangaDetailDTO) -> String {
        displayTitle(for: manga)
    }

    func reviewNavigationState() -> ReviewNavigationState {
        guard let detail else { return .hidden }
        return .available(title: reviewTitle(for: detail))
    }

    func favoriteItem(for manga: MangaDetailDTO) -> MyListCollectionItem {
        MyListCollectionItem(
            malId: manga.malId,
            mediaKind: .manga,
            title: displayTitle(for: manga),
            subtitle: manga.titleEnglish ?? manga.title,
            imageURLString: posterURL(for: manga)?.absoluteString,
            addedAt: Date()
        )
    }

    func sections(for manga: MangaDetailDTO) -> [Section] {
        var result: [Section] = [
            .header,
            .highlights,
            .score
        ]
        if hasSynopsis(for: manga) {
            result.append(.synopsis)
        }
        if hasPublicationInfo(for: manga) || hasThemes(for: manga) || !hasSynopsis(for: manga) {
            result.append(.publication)
        }
        return result
    }

    // MARK: - Type & Status

    func mangaTypeDisplayText(for manga: MangaDetailDTO) -> String {
        guard let raw = manga.type?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return "-"
        }
        let lower = raw.lowercased()
        if lower == "manga" { return "漫畫" }
        if lower == "novel" { return "小說" }
        if lower == "one-shot" || lower == "one shot" { return "單篇" }
        if lower == "doujinshi" { return "同人誌" }
        if lower == "manhwa" { return "韓漫" }
        if lower == "manhua" { return "條漫／華漫" }
        if lower == "oel" { return "OEL" }
        return raw
    }

    func mangaStatusDisplayText(for manga: MangaDetailDTO) -> String {
        guard let raw = manga.status?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return "-"
        }
        let lower = raw.lowercased()
        if lower == "finished" { return "已完結" }
        if lower == "publishing" { return "連載中" }
        if lower == "on hiatus" { return "休刊" }
        if lower == "discontinued" { return "中止" }
        if lower == "not yet published" { return "尚未發行" }
        return raw
    }

    func chaptersDisplayText(for manga: MangaDetailDTO) -> String {
        guard let n = manga.chapters else { return "-" }
        return n == 0 ? "未知" : formatNumber(n) + " 話"
    }

    func volumesDisplayText(for manga: MangaDetailDTO) -> String {
        guard let n = manga.volumes else { return "-" }
        return n == 0 ? "未知" : formatNumber(n) + " 卷"
    }

    func publishedPeriodDisplayText(for manga: MangaDetailDTO) -> String {
        AnimeDetailDateFormatting.slashSeparatedPeriod(from: manga.published) ?? "-"
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

    // MARK: - Score

    func scoreDisplayText(for manga: MangaDetailDTO) -> String {
        guard let score = manga.score else { return "-" }
        return String(format: "%.2f", score) + " / 10.0"
    }

    // MARK: - Synopsis & Themes

    func synopsisDisplayText(for manga: MangaDetailDTO) -> String {
        cleanedSynopsis(for: manga) ?? "-"
    }

    func hasSynopsis(for manga: MangaDetailDTO) -> Bool {
        guard let synopsis = cleanedSynopsis(for: manga) else { return false }
        return !synopsis.isEmpty
    }

    func hasThemes(for manga: MangaDetailDTO) -> Bool {
        guard let themes = manga.themes, !themes.isEmpty else { return false }
        return themes.contains { theme in
            let name = theme.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return !name.isEmpty
        }
    }

    func themeDisplayItems(for manga: MangaDetailDTO) -> [AnimeRelatedEntityDTO] {
        guard let themes = manga.themes else { return [] }
        return themes
            .filter { theme in
                let name = theme.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return !name.isEmpty
            }
            .sorted {
                ($0.name ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending
            }
    }

    // MARK: - Section Visibility

    func hasPublicationInfo(for manga: MangaDetailDTO) -> Bool {
        joinedNames(from: manga.authors) != "-"
            || joinedNames(from: manga.serializations) != "-"
            || joinedNames(from: manga.genres) != "-"
            || joinedNames(from: manga.demographics) != "-"
    }

    // MARK: - Private Methods

    private func cleanedSynopsis(for manga: MangaDetailDTO) -> String? {
        guard var synopsis = manga.synopsis?.trimmingCharacters(in: .whitespacesAndNewlines), !synopsis.isEmpty else {
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
