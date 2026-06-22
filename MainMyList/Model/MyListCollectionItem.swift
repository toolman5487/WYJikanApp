//
//  MyListCollectionItem.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import Foundation
import SwiftData

// MARK: - MyListCollectionItem

@Model
final class MyListCollectionItem {

    #Unique<MyListCollectionItem>([\.malId, \.mediaKindRawValue])

    // MARK: - Stored Properties

    var malId: Int
    var mediaKindRawValue: String
    var title: String
    var subtitle: String?
    var imageURLString: String?
    var genreNamesRawValue: String?
    var type: String?
    var year: Int?
    var addedAt: Date
    var animeWatchStatusRawValue: String?
    var currentEpisode: Int?
    var totalEpisodesSnapshot: Int?
    var mangaReadingStatusRawValue: String?
    var currentChapter: Int?
    var totalChaptersSnapshot: Int?
    var progressUpdatedAt: Date?

    // MARK: - Lifecycle

    init(
        malId: Int,
        mediaKind: MyListMediaKind,
        title: String,
        subtitle: String?,
        imageURLString: String?,
        genreNames: [String] = [],
        type: String? = nil,
        year: Int? = nil,
        addedAt: Date,
        animeWatchStatus: AnimeWatchStatus? = nil,
        currentEpisode: Int? = nil,
        totalEpisodesSnapshot: Int? = nil,
        mangaReadingStatus: MangaReadingStatus? = nil,
        currentChapter: Int? = nil,
        totalChaptersSnapshot: Int? = nil,
        progressUpdatedAt: Date? = nil
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
        self.animeWatchStatusRawValue = animeWatchStatus?.rawValue
        self.currentEpisode = Self.normalizedProgressValue(currentEpisode)
        self.totalEpisodesSnapshot = Self.normalizedProgressValue(totalEpisodesSnapshot)
        self.mangaReadingStatusRawValue = mangaReadingStatus?.rawValue
        self.currentChapter = Self.normalizedProgressValue(currentChapter)
        self.totalChaptersSnapshot = Self.normalizedProgressValue(totalChaptersSnapshot)
        self.progressUpdatedAt = progressUpdatedAt
    }
}

// MARK: - AnimeWatchStatus

nonisolated enum AnimeWatchStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case planned
    case watching
    case onHold
    case completed
    case dropped

    var id: String { rawValue }

    var title: String {
        switch self {
        case .planned:
            return "想看"
        case .watching:
            return "觀看中"
        case .onHold:
            return "暫停"
        case .completed:
            return "已看完"
        case .dropped:
            return "棄番"
        }
    }

    var systemImageName: String {
        switch self {
        case .planned:
            return "bookmark"
        case .watching:
            return "play.circle"
        case .onHold:
            return "pause.circle"
        case .completed:
            return "checkmark.circle"
        case .dropped:
            return "xmark.circle"
        }
    }
}

// MARK: - MangaReadingStatus

nonisolated enum MangaReadingStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case planned
    case reading
    case onHold
    case completed
    case dropped

    var id: String { rawValue }

    var title: String {
        switch self {
        case .planned:
            return "想讀"
        case .reading:
            return "閱讀中"
        case .onHold:
            return "暫停"
        case .completed:
            return "已完成"
        case .dropped:
            return "停讀"
        }
    }

    var systemImageName: String {
        switch self {
        case .planned:
            return "bookmark"
        case .reading:
            return "book"
        case .onHold:
            return "pause.circle"
        case .completed:
            return "checkmark.circle"
        case .dropped:
            return "xmark.circle"
        }
    }
}

// MARK: - MyListItemDraft

nonisolated struct MyListItemDraft: Sendable {
    let malId: Int
    let mediaKind: MyListMediaKind
    let title: String
    let subtitle: String?
    let imageURLString: String?
    let genreNames: [String]
    let type: String?
    let year: Int?
    let addedAt: Date
    let animeWatchStatus: AnimeWatchStatus?
    let currentEpisode: Int?
    let totalEpisodes: Int?
    let mangaReadingStatus: MangaReadingStatus?
    let currentChapter: Int?
    let totalChapters: Int?
    let progressUpdatedAt: Date?

    init(
        malId: Int,
        mediaKind: MyListMediaKind,
        title: String,
        subtitle: String?,
        imageURLString: String?,
        genreNames: [String] = [],
        type: String? = nil,
        year: Int? = nil,
        addedAt: Date,
        animeWatchStatus: AnimeWatchStatus? = nil,
        currentEpisode: Int? = nil,
        totalEpisodes: Int? = nil,
        mangaReadingStatus: MangaReadingStatus? = nil,
        currentChapter: Int? = nil,
        totalChapters: Int? = nil,
        progressUpdatedAt: Date? = nil
    ) {
        self.malId = malId
        self.mediaKind = mediaKind
        self.title = title
        self.subtitle = subtitle
        self.imageURLString = imageURLString
        self.genreNames = genreNames
        self.type = type
        self.year = year
        self.addedAt = addedAt
        self.animeWatchStatus = animeWatchStatus
        self.currentEpisode = currentEpisode
        self.totalEpisodes = totalEpisodes
        self.mangaReadingStatus = mangaReadingStatus
        self.currentChapter = currentChapter
        self.totalChapters = totalChapters
        self.progressUpdatedAt = progressUpdatedAt
    }
}

// MARK: - MyListItemSnapshot

nonisolated struct MyListItemSnapshot: Identifiable, Hashable, Sendable {
    let malId: Int
    let mediaKind: MyListMediaKind
    let title: String
    let subtitle: String?
    let imageURLString: String?
    let genreNames: [String]
    let type: String?
    let year: Int?
    let addedAt: Date
    let animeWatchStatus: AnimeWatchStatus
    let currentEpisode: Int?
    let totalEpisodes: Int?
    let mangaReadingStatus: MangaReadingStatus
    let currentChapter: Int?
    let totalChapters: Int?
    let progressUpdatedAt: Date?

    var id: String {
        "\(mediaKind.rawValue)-\(malId)"
    }

    var imageURL: URL? {
        guard let imageURLString else { return nil }
        return URL(string: imageURLString)
    }

    func watchProgressFraction(totalEpisodes: Int? = nil) -> Double? {
        let resolvedTotalEpisodes = Self.normalizedProgressValue(totalEpisodes) ?? self.totalEpisodes
        guard
            let currentEpisode,
            let resolvedTotalEpisodes,
            resolvedTotalEpisodes > 0
        else {
            return nil
        }

        return min(Double(currentEpisode) / Double(resolvedTotalEpisodes), 1)
    }

    func watchProgressSummary(totalEpisodes: Int? = nil) -> String {
        let resolvedTotalEpisodes = Self.normalizedProgressValue(totalEpisodes) ?? self.totalEpisodes

        switch (animeWatchStatus, currentEpisode, resolvedTotalEpisodes) {
        case (.planned, nil, _):
            return "尚未開始"
        case (.completed, _, let totalEpisodes?):
            return "已看完 \(totalEpisodes) 集"
        case (.completed, let currentEpisode?, nil):
            return "已看完 \(currentEpisode) 集"
        case (.completed, nil, nil):
            return "已看完"
        case let (status, currentEpisode?, totalEpisodes?):
            return "\(status.title) \(currentEpisode) / \(totalEpisodes) 集"
        case let (status, currentEpisode?, nil):
            return "\(status.title)到第 \(currentEpisode) 集"
        case let (status, nil, _):
            return status.title
        }
    }

    func readingProgressFraction(totalChapters: Int? = nil) -> Double? {
        let resolvedTotalChapters = Self.normalizedProgressValue(totalChapters) ?? self.totalChapters
        guard
            let currentChapter,
            let resolvedTotalChapters,
            resolvedTotalChapters > 0
        else {
            return nil
        }

        return min(Double(currentChapter) / Double(resolvedTotalChapters), 1)
    }

    func readingProgressSummary(totalChapters: Int? = nil) -> String {
        let resolvedTotalChapters = Self.normalizedProgressValue(totalChapters) ?? self.totalChapters

        switch (mangaReadingStatus, currentChapter, resolvedTotalChapters) {
        case (.planned, nil, _):
            return "尚未開始"
        case (.completed, _, let totalChapters?):
            return "已讀完 \(totalChapters) 話"
        case (.completed, let currentChapter?, nil):
            return "已讀完 \(currentChapter) 話"
        case (.completed, nil, nil):
            return "已完成"
        case let (status, currentChapter?, totalChapters?):
            return "\(status.title) \(currentChapter) / \(totalChapters) 話"
        case let (status, currentChapter?, nil):
            return "\(status.title)到 \(currentChapter) 話"
        case let (status, nil, _):
            return status.title
        }
    }

    private static func normalizedProgressValue(_ value: Int?) -> Int? {
        guard let value, value > 0 else { return nil }
        return value
    }
}

// MARK: - MyListCollectionItem Helpers

extension MyListCollectionItem {

    convenience init(draft: MyListItemDraft) {
        self.init(
            malId: draft.malId,
            mediaKind: draft.mediaKind,
            title: draft.title,
            subtitle: draft.subtitle,
            imageURLString: draft.imageURLString,
            genreNames: draft.genreNames,
            type: draft.type,
            year: draft.year,
            addedAt: draft.addedAt,
            animeWatchStatus: draft.animeWatchStatus,
            currentEpisode: draft.currentEpisode,
            totalEpisodesSnapshot: draft.totalEpisodes,
            mangaReadingStatus: draft.mangaReadingStatus,
            currentChapter: draft.currentChapter,
            totalChaptersSnapshot: draft.totalChapters,
            progressUpdatedAt: draft.progressUpdatedAt
        )
    }

    // MARK: - Computed Properties

    var mediaKind: MyListMediaKind {
        MyListMediaKind(rawValue: mediaKindRawValue) ?? .anime
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

    var animeWatchStatus: AnimeWatchStatus {
        get {
            guard let animeWatchStatusRawValue else { return .planned }
            return AnimeWatchStatus(rawValue: animeWatchStatusRawValue) ?? .planned
        }
        set {
            animeWatchStatusRawValue = newValue.rawValue
        }
    }

    var mangaReadingStatus: MangaReadingStatus {
        get {
            guard let mangaReadingStatusRawValue else { return .planned }
            return MangaReadingStatus(rawValue: mangaReadingStatusRawValue) ?? .planned
        }
        set {
            mangaReadingStatusRawValue = newValue.rawValue
        }
    }

    var snapshot: MyListItemSnapshot {
        MyListItemSnapshot(
            malId: malId,
            mediaKind: mediaKind,
            title: title,
            subtitle: subtitle,
            imageURLString: imageURLString,
            genreNames: genreNames,
            type: type,
            year: year,
            addedAt: addedAt,
            animeWatchStatus: animeWatchStatus,
            currentEpisode: currentEpisode,
            totalEpisodes: totalEpisodesSnapshot,
            mangaReadingStatus: mangaReadingStatus,
            currentChapter: currentChapter,
            totalChapters: totalChaptersSnapshot,
            progressUpdatedAt: progressUpdatedAt
        )
    }

    // MARK: - Progress Mutation

    func updateAnimeWatchProgress(
        status: AnimeWatchStatus,
        currentEpisode: Int?,
        totalEpisodes: Int?,
        updatedAt: Date = Date()
    ) {
        let normalizedTotalEpisodes = Self.normalizedProgressValue(totalEpisodes)
        let normalizedCurrentEpisode = Self.clampedProgressValue(
            currentEpisode,
            totalValue: normalizedTotalEpisodes
        )

        animeWatchStatus = status
        self.currentEpisode = normalizedCurrentEpisode
        totalEpisodesSnapshot = normalizedTotalEpisodes
        progressUpdatedAt = updatedAt
    }

    func updateMangaReadingProgress(
        status: MangaReadingStatus,
        currentChapter: Int?,
        totalChapters: Int?,
        updatedAt: Date = Date()
    ) {
        let normalizedTotalChapters = Self.normalizedProgressValue(totalChapters)
        let normalizedCurrentChapter = Self.clampedProgressValue(
            currentChapter,
            totalValue: normalizedTotalChapters
        )

        mangaReadingStatus = status
        self.currentChapter = normalizedCurrentChapter
        totalChaptersSnapshot = normalizedTotalChapters
        progressUpdatedAt = updatedAt
    }

    // MARK: - Normalization

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
        DisplayTextFormatting.nonEmpty(text)
    }

    private static func normalizedProgressValue(_ value: Int?) -> Int? {
        guard let value, value > 0 else { return nil }
        return value
    }

    private static func clampedProgressValue(_ value: Int?, totalValue: Int?) -> Int? {
        guard let value = normalizedProgressValue(value) else { return nil }
        guard let totalValue else { return value }
        return min(value, totalValue)
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
