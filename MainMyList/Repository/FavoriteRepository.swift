//
//  FavoriteRepository.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/14.
//

import Foundation
import Combine
import SwiftData

enum RepositoryConnectionError: LocalizedError {
    case notConnected

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "資料庫尚未連線，請重新啟動 App。"
        }
    }
}

struct FavoriteSnapshot: Equatable, Sendable {
    let animeIDs: Set<Int>
    let mangaIDs: Set<Int>
}

protocol FavoriteRepository: AnyObject {
    func connect(modelContext: ModelContext)

    var favoriteSnapshotPublisher: AnyPublisher<FavoriteSnapshot, Never> { get }
    var myListPublisher: AnyPublisher<[MyListItemSnapshot], Never> { get }

    func reloadFavorites() throws

    func toggleFavorite(
        malId: Int,
        mediaKind: MyListMediaKind,
        draft: MyListItemDraft?
    ) throws -> Bool

    func remove(malId: Int, mediaKind: MyListMediaKind) throws

    func removeAllFavorites() throws

    func updateAnimeWatchProgress(
        malId: Int,
        status: AnimeWatchStatus,
        currentEpisode: Int?,
        totalEpisodes: Int?
    ) throws

    func updateMangaReadingProgress(
        malId: Int,
        status: MangaReadingStatus,
        currentChapter: Int?,
        totalChapters: Int?
    ) throws
}

final class SwiftDataFavoriteRepository: FavoriteRepository {
    var favoriteSnapshotPublisher: AnyPublisher<FavoriteSnapshot, Never> {
        snapshotSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var myListPublisher: AnyPublisher<[MyListItemSnapshot], Never> {
        myListSubject.eraseToAnyPublisher()
    }

    private let snapshotSubject = CurrentValueSubject<FavoriteSnapshot, Never>(
        FavoriteSnapshot(animeIDs: [], mangaIDs: [])
    )
    private let myListSubject = CurrentValueSubject<[MyListItemSnapshot], Never>([])

    private var modelContext: ModelContext?

    init() {}

    func connect(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func reloadFavorites() throws {
        let modelContext = try requireModelContext()
        try publish(from: modelContext)
    }

    func toggleFavorite(
        malId: Int,
        mediaKind: MyListMediaKind,
        draft: MyListItemDraft? = nil
    ) throws -> Bool {
        let modelContext = try requireModelContext()

        if let existing = try fetchFavoriteItem(
            malId: malId,
            mediaKind: mediaKind,
            modelContext: modelContext
        ) {
            modelContext.delete(existing)

            do {
                try modelContext.save()
                try publish(from: modelContext)
                return false
            } catch {
                modelContext.rollback()
                throw error
            }
        }

        guard let draft else {
            return false
        }

        modelContext.insert(MyListCollectionItem(draft: draft))

        do {
            try modelContext.save()
            try publish(from: modelContext)
            return true
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func remove(malId: Int, mediaKind: MyListMediaKind) throws {
        let modelContext = try requireModelContext()
        guard let item = try fetchFavoriteItem(
            malId: malId,
            mediaKind: mediaKind,
            modelContext: modelContext
        ) else {
            return
        }
        modelContext.delete(item)

        do {
            try modelContext.save()
            try publish(from: modelContext)
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func removeAllFavorites() throws {
        let modelContext = try requireModelContext()
        let items = try fetchAllItems(from: modelContext)

        for item in items {
            modelContext.delete(item)
        }

        do {
            try modelContext.save()
            try publish(from: modelContext)
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func updateAnimeWatchProgress(
        malId: Int,
        status: AnimeWatchStatus,
        currentEpisode: Int?,
        totalEpisodes: Int?
    ) throws {
        let modelContext = try requireModelContext()
        guard let item = try fetchFavoriteItem(
            malId: malId,
            mediaKind: .anime,
            modelContext: modelContext
        ) else {
            return
        }
        item.updateAnimeWatchProgress(
            status: status,
            currentEpisode: currentEpisode,
            totalEpisodes: totalEpisodes
        )
        try saveAndPublish(modelContext)
    }

    func updateMangaReadingProgress(
        malId: Int,
        status: MangaReadingStatus,
        currentChapter: Int?,
        totalChapters: Int?
    ) throws {
        let modelContext = try requireModelContext()
        guard let item = try fetchFavoriteItem(
            malId: malId,
            mediaKind: .manga,
            modelContext: modelContext
        ) else {
            return
        }
        item.updateMangaReadingProgress(
            status: status,
            currentChapter: currentChapter,
            totalChapters: totalChapters
        )
        try saveAndPublish(modelContext)
    }

    private func requireModelContext() throws -> ModelContext {
        guard let modelContext else {
            throw RepositoryConnectionError.notConnected
        }
        return modelContext
    }

    private func publish(from modelContext: ModelContext) throws {
        let items = try fetchAllItems(from: modelContext)
        myListSubject.send(items.map(\.snapshot))
        snapshotSubject.send(makeSnapshot(from: items))
    }

    private func saveAndPublish(_ modelContext: ModelContext) throws {
        do {
            try modelContext.save()
            try publish(from: modelContext)
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    private func fetchAllItems(from modelContext: ModelContext) throws -> [MyListCollectionItem] {
        try modelContext.fetch(
            FetchDescriptor<MyListCollectionItem>(
                sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
            )
        )
    }

    private func makeSnapshot(from items: [MyListCollectionItem]) -> FavoriteSnapshot {
        var animeIDs: Set<Int> = []
        var mangaIDs: Set<Int> = []

        for item in items {
            switch item.mediaKind {
            case .anime:
                animeIDs.insert(item.malId)
            case .manga:
                mangaIDs.insert(item.malId)
            }
        }

        return FavoriteSnapshot(animeIDs: animeIDs, mangaIDs: mangaIDs)
    }

    private func fetchFavoriteItem(
        malId: Int,
        mediaKind: MyListMediaKind,
        modelContext: ModelContext
    ) throws -> MyListCollectionItem? {
        let mediaKindRawValue = mediaKind.rawValue
        var descriptor = FetchDescriptor<MyListCollectionItem>(
            predicate: #Predicate<MyListCollectionItem> {
                $0.malId == malId && $0.mediaKindRawValue == mediaKindRawValue
            }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}
