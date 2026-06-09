//
//  AnimeDetailViewModel+Presentation.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import Foundation

extension AnimeDetailViewModel {

    enum Section: Identifiable {
        case header
        case highlights
        case basicInfo
        case episodes
        case score
        case trailer
        case synopsis
        case characters
        case staff
        case pictures
        case recommendations

        var id: String {
            switch self {
            case .header: return "header"
            case .highlights: return "highlights"
            case .basicInfo: return "basicInfo"
            case .episodes: return "episodes"
            case .score: return "score"
            case .trailer: return "trailer"
            case .synopsis: return "synopsis"
            case .characters: return "characters"
            case .staff: return "staff"
            case .pictures: return "pictures"
            case .recommendations: return "recommendations"
            }
        }
    }

    // MARK: - Header & Media

    func displayTitle(for anime: AnimeDetailDTO) -> String {
        preferredTitle(
            japaneseTitle: anime.titleJapanese,
            englishTitle: anime.titleEnglish,
            fallbackTitle: anime.title,
            emptyFallback: "🎬"
        )
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

    func reviewTitle(for anime: AnimeDetailDTO) -> String {
        displayTitle(for: anime)
    }

    func reviewNavigationState() -> DetailNavigationToolbarReviewState {
        guard let detail else { return .loading }
        return .available(title: reviewTitle(for: detail))
    }

    func shareNavigationState() -> DetailNavigationToolbarShareState {
        guard let detail,
              let url = malWorkPageURL(for: detail) else {
            return .loading
        }
        let title = displayTitle(for: detail)
        return .available(
            title: title,
            message: shareMessageText(for: detail),
            url: url
        )
    }

    func shareMessageText(for anime: AnimeDetailDTO) -> String {
        let title = displayTitle(for: anime)
        let details = shareDetailsText(for: anime)
        guard !details.isEmpty else { return title }
        return "\(title)\n\n\(details)"
    }

    func favoriteItem(for anime: AnimeDetailDTO) -> MyListCollectionItem {
        MyListCollectionItem(
            malId: anime.malId,
            mediaKind: .anime,
            title: displayTitle(for: anime),
            subtitle: preferredSecondaryTitle(
                primaryTitle: displayTitle(for: anime),
                japaneseTitle: anime.titleJapanese,
                englishTitle: anime.titleEnglish,
                fallbackTitle: anime.title
            ),
            imageURLString: posterURL(for: anime)?.absoluteString,
            genreNames: (anime.genres ?? []).compactMap(\.name),
            type: anime.type,
            year: anime.year,
            addedAt: Date()
        )
    }

    func sections(for anime: AnimeDetailDTO) -> [Section] {
        AnimeDetailSectionBuilder().sections(
            for: AnimeDetailSectionAvailability(
                hasEpisodes: hasEpisodes(for: anime),
                hasTrailer: hasTrailer(for: anime),
                hasSynopsis: hasSynopsis(for: anime),
                hasCharacters: hasCharacters,
                hasStaffOrThemes: hasStaffInfo(for: anime) || hasThemes(for: anime),
                hasPictures: hasPictures,
                hasRecommendations: hasRecommendations
            )
        )
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
        trailerWatchURL(for: anime) != nil
    }

    func trailerEmbedURL(for anime: AnimeDetailDTO) -> URL? {
        guard let trailer = anime.trailer else { return nil }
        if let id = resolvedYouTubeVideoId(from: trailer),
           let url = YouTubeVideoURLResolver.embedURL(videoID: id) {
            return url
        }
        if let url = url(from: trailer.embedUrl) {
            return url
        }
        return nil
    }

    func trailerWatchURL(for anime: AnimeDetailDTO) -> URL? {
        guard let trailer = anime.trailer else { return nil }
        if let id = resolvedYouTubeVideoId(from: trailer),
           let url = YouTubeVideoURLResolver.watchURL(videoID: id) {
            return url
        }
        return url(from: trailer.url)
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
        if let presentation = AnimeDetailDateFormatting.localBroadcastPresentation(from: anime.broadcast) {
            return presentation.displayText
        }

        guard let broadcast = anime.broadcast else { return nil }
        if let string = broadcast.string?.trimmingCharacters(in: .whitespacesAndNewlines), !string.isEmpty {
            return AnimeDetailDateFormatting.translateBroadcastEnglishString(string)
        }

        let day = broadcast.day?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let time = broadcast.time?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !day.isEmpty, !time.isEmpty else { return nil }
        return "\(AnimeDetailDateFormatting.weekdayChinese(from: day)) \(time)"
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

    private func shareDetailsText(for anime: AnimeDetailDTO) -> String {
        let releaseText = shareValue(seasonText(for: anime)) ?? shareValue(airedPeriodDisplayText(for: anime))

        return [
            shareLine(title: "類型", value: typeDisplayText(for: anime)),
            shareLine(title: "評分", value: scoreDisplayText(for: anime)),
            shareLine(title: "排名", value: anime.rank.map { "#\($0)" }),
            shareLine(title: "人氣", value: anime.popularity.map { "#\($0)" }),
            shareLine(title: "收藏", value: anime.favorites.map(formatNumber)),
            shareLine(title: "狀態", value: statusDisplayText(for: anime)),
            shareLine(title: "播出", value: releaseText)
        ]
        .compactMap { $0 }
        .joined(separator: "\n")
    }

    private func shareLine(title: String, value: String?) -> String? {
        guard let value = shareValue(value) else { return nil }
        return "\(title)：\(value)"
    }

    private func shareValue(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty,
              value != "-" else {
            return nil
        }
        return value
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

    var hasCharacters: Bool {
        !allCharacterRoles.isEmpty
    }

    var hasRecommendations: Bool {
        !allRecommendations.isEmpty
    }

    var previewCharacterRoles: [AnimeCharacterRoleDTO] {
        Array(allCharacterRoles.prefix(8))
    }

    var allCharacterRoles: [AnimeCharacterRoleDTO] {
        characterRoles.filter { $0.character != nil }
    }

    var previewRecommendations: [AnimeRecommendationDTO] {
        Array(allRecommendations.prefix(6))
    }

    var allRecommendations: [AnimeRecommendationDTO] {
        recommendationItems.filter { $0.entry != nil }
    }

    func hasEpisodes(for anime: AnimeDetailDTO) -> Bool {
        anime.episodes != nil || anime.status != nil
    }

    func characterName(_ character: AnimeCharacterEntryDTO) -> String {
        preferredDisplayName(
            kanjiName: character.nameKanji,
            fallbackName: character.name,
            emptyFallback: "未命名角色"
        )
    }

    func characterImageURL(_ character: AnimeCharacterEntryDTO) -> URL? {
        let urlString =
            character.images?.webp?.largeImageUrl ??
            character.images?.jpg?.largeImageUrl ??
            character.images?.webp?.imageUrl ??
            character.images?.jpg?.imageUrl
        guard let urlString else { return nil }
        return URL(string: urlString)
    }

    func characterRoleText(_ role: AnimeCharacterRoleDTO) -> String {
        guard let trimmed = role.role?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return "未標示定位"
        }
        return trimmed
    }

    func voiceActorSummary(for role: AnimeCharacterRoleDTO) -> String {
        guard let voiceActor = preferredVoiceActor(for: role),
              let person = voiceActor.person else {
            return "暫無聲優資料"
        }

        let resolvedName = preferredDisplayName(
            kanjiName: person.nameKanji,
            fallbackName: person.name,
            emptyFallback: "未命名聲優"
        )
        let language = trimmedText(voiceActor.language)
        guard let language, !language.isEmpty else {
            return resolvedName
        }
        return "\(resolvedName) · \(language)"
    }

    private func preferredVoiceActor(for role: AnimeCharacterRoleDTO) -> AnimeCharacterVoiceActorDTO? {
        let voiceActors = (role.voiceActors ?? []).filter { $0.person != nil }
        return voiceActors.first(where: isJapaneseVoiceActor(_:)) ?? voiceActors.first
    }

    private func isJapaneseVoiceActor(_ voiceActor: AnimeCharacterVoiceActorDTO) -> Bool {
        trimmedText(voiceActor.language)?.localizedCaseInsensitiveCompare("Japanese") == .orderedSame
    }

    private func preferredDisplayName(
        kanjiName: String?,
        fallbackName: String?,
        emptyFallback: String
    ) -> String {
        trimmedText(kanjiName) ?? trimmedText(fallbackName) ?? emptyFallback
    }

    private func preferredTitle(
        japaneseTitle: String?,
        englishTitle: String?,
        fallbackTitle: String?,
        emptyFallback: String
    ) -> String {
        trimmedText(japaneseTitle) ?? trimmedText(englishTitle) ?? trimmedText(fallbackTitle) ?? emptyFallback
    }

    private func preferredSecondaryTitle(
        primaryTitle: String,
        japaneseTitle: String?,
        englishTitle: String?,
        fallbackTitle: String?
    ) -> String? {
        let candidates = [
            trimmedText(englishTitle),
            trimmedText(fallbackTitle),
            trimmedText(japaneseTitle)
        ]

        for candidate in candidates {
            if let candidate, candidate != primaryTitle {
                return candidate
            }
        }

        return nil
    }

    private func trimmedText(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }
        return value
    }

    func recommendationTitle(_ recommendation: AnimeRecommendationDTO) -> String {
        preferredTitle(
            japaneseTitle: recommendation.entry?.titleJapanese,
            englishTitle: recommendation.entry?.titleEnglish,
            fallbackTitle: recommendation.entry?.title,
            emptyFallback: "未命名作品"
        )
    }

    func recommendationImageURL(_ recommendation: AnimeRecommendationDTO) -> URL? {
        let urlString =
            recommendation.entry?.images?.webp?.largeImageUrl ??
            recommendation.entry?.images?.jpg?.largeImageUrl ??
            recommendation.entry?.images?.webp?.imageUrl ??
            recommendation.entry?.images?.jpg?.imageUrl
        guard let urlString else { return nil }
        return URL(string: urlString)
    }

    func recommendationSummaryText(_ recommendation: AnimeRecommendationDTO) -> String {
        if let content = recommendation.content?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " "),
           !content.isEmpty {
            return String(content.prefix(52))
        }

        if let votes = recommendation.votes {
            return "\(formatNumber(votes)) 人推薦"
        }

        return "相似作品推薦"
    }

    func episodesSummaryTitle(for anime: AnimeDetailDTO) -> String {
        if let episodeCount = anime.episodes {
            return "共 \(episodeCount) 集"
        }
        return "查看播出集數"
    }

    func episodesSummarySubtitle(for anime: AnimeDetailDTO) -> String {
        let status = statusDisplayText(for: anime)
        let schedule = weeklyBroadcastScheduleText(for: anime) ?? airedPeriodDisplayText(for: anime)
        if let schedule, schedule != "-" {
            return "\(status) · \(schedule)"
        }
        return status
    }

    func imagePreviewItems(for anime: AnimeDetailDTO) -> [ImagePreviewItem] {
        AnimeDetailImagePreviewBuilder().items(
            animeId: anime.malId,
            posterURL: posterURL(for: anime),
            pictureItems: pictureItems
        )
    }

    func initialPreviewIndex(
        for items: [ImagePreviewItem],
        selectedImageURL: URL?
    ) -> Int {
        AnimeDetailImagePreviewBuilder().initialIndex(
            for: items,
            selectedImageURL: selectedImageURL
        )
    }

    func initialPreviewIndex(
        for anime: AnimeDetailDTO,
        items: [ImagePreviewItem],
        selectedPictureIndex: Int
    ) -> Int {
        AnimeDetailImagePreviewBuilder().initialIndex(
            for: items,
            selectedPictureIndex: selectedPictureIndex,
            hasPoster: posterURL(for: anime) != nil
        )
    }

    // MARK: - Private Methods

    private func resolvedYouTubeVideoId(from trailer: AnimeDetailTrailerDTO) -> String? {
        if let id = trimmedText(trailer.youtubeId) {
            return id
        }

        if let embedURL = url(from: trailer.embedUrl),
           let id = YouTubeVideoURLResolver.videoID(from: embedURL) {
            return id
        }

        if let watchURL = url(from: trailer.url),
           let id = YouTubeVideoURLResolver.videoID(from: watchURL) {
            return id
        }

        return nil
    }

    private func url(from value: String?) -> URL? {
        guard let text = trimmedText(value) else { return nil }
        return URL(string: text)
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
