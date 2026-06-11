//
//  MyListCollectionItem.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import Foundation
import SwiftData

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
    var mangaReadingStatusRawValue: String?
    var currentChapter: Int?
    var totalChaptersSnapshot: Int?
    var progressUpdatedAt: Date?

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
        self.mangaReadingStatusRawValue = mangaReadingStatus?.rawValue
        self.currentChapter = Self.normalizedChapter(currentChapter)
        self.totalChaptersSnapshot = Self.normalizedChapter(totalChaptersSnapshot)
        self.progressUpdatedAt = progressUpdatedAt
    }
}

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

    var mangaReadingStatus: MangaReadingStatus {
        get {
            guard let mangaReadingStatusRawValue else { return .planned }
            return MangaReadingStatus(rawValue: mangaReadingStatusRawValue) ?? .planned
        }
        set {
            mangaReadingStatusRawValue = newValue.rawValue
        }
    }

    var hasMangaReadingProgress: Bool {
        mangaReadingStatusRawValue != nil || currentChapter != nil
    }

    func readingProgressFraction(totalChapters: Int? = nil) -> Double? {
        let resolvedTotalChapters = Self.normalizedChapter(totalChapters) ?? totalChaptersSnapshot
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
        let status = mangaReadingStatus
        let resolvedTotalChapters = Self.normalizedChapter(totalChapters) ?? totalChaptersSnapshot

        switch (status, currentChapter, resolvedTotalChapters) {
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

    func updateMangaReadingProgress(
        status: MangaReadingStatus,
        currentChapter: Int?,
        totalChapters: Int?,
        updatedAt: Date = Date()
    ) {
        let normalizedTotalChapters = Self.normalizedChapter(totalChapters)
        let normalizedCurrentChapter = Self.clampedChapter(
            currentChapter,
            totalChapters: normalizedTotalChapters
        )

        mangaReadingStatus = status
        self.currentChapter = normalizedCurrentChapter
        totalChaptersSnapshot = normalizedTotalChapters
        progressUpdatedAt = updatedAt
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

    private static func normalizedChapter(_ chapter: Int?) -> Int? {
        guard let chapter, chapter > 0 else { return nil }
        return chapter
    }

    private static func clampedChapter(_ chapter: Int?, totalChapters: Int?) -> Int? {
        guard let chapter = normalizedChapter(chapter) else { return nil }
        guard let totalChapters else { return chapter }
        return min(chapter, totalChapters)
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
