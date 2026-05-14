//
//  FavoriteRepository.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/14.
//

import Foundation
import Combine
import SwiftData

struct FavoriteSnapshot: Equatable, Sendable {
    let animeIDs: Set<Int>
    let mangaIDs: Set<Int>
}

protocol FavoriteRepository: AnyObject {
    var favoriteSnapshotPublisher: AnyPublisher<FavoriteSnapshot, Never> { get }

    func reloadFavorites(from modelContext: ModelContext) throws

    func toggleFavorite(
        malId: Int,
        mediaKind: MyListMediaKind,
        modelContext: ModelContext,
        makeItem: (() -> MyListCollectionItem)?
    ) throws -> Bool

    func remove(
        _ item: MyListCollectionItem,
        from modelContext: ModelContext
    ) throws
}

final class SwiftDataFavoriteRepository: FavoriteRepository {
    static let shared = SwiftDataFavoriteRepository()

    var favoriteSnapshotPublisher: AnyPublisher<FavoriteSnapshot, Never> {
        snapshotSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private let snapshotSubject = CurrentValueSubject<FavoriteSnapshot, Never>(
        FavoriteSnapshot(animeIDs: [], mangaIDs: [])
    )

    private init() {}

    func reloadFavorites(from modelContext: ModelContext) throws {
        snapshotSubject.send(try makeSnapshot(from: modelContext))
    }

    func toggleFavorite(
        malId: Int,
        mediaKind: MyListMediaKind,
        modelContext: ModelContext,
        makeItem: (() -> MyListCollectionItem)? = nil
    ) throws -> Bool {
        if let existing = try fetchFavoriteItem(
            malId: malId,
            mediaKind: mediaKind,
            modelContext: modelContext
        ) {
            modelContext.delete(existing)

            do {
                try modelContext.save()
                try publishFavorites(from: modelContext)
                return false
            } catch {
                modelContext.rollback()
                throw error
            }
        }

        guard let makeItem else {
            return false
        }

        modelContext.insert(makeItem())

        do {
            try modelContext.save()
            try publishFavorites(from: modelContext)
            return true
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func remove(
        _ item: MyListCollectionItem,
        from modelContext: ModelContext
    ) throws {
        modelContext.delete(item)

        do {
            try modelContext.save()
            try publishFavorites(from: modelContext)
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    private func publishFavorites(from modelContext: ModelContext) throws {
        snapshotSubject.send(try makeSnapshot(from: modelContext))
    }

    private func makeSnapshot(from modelContext: ModelContext) throws -> FavoriteSnapshot {
        let items = try modelContext.fetch(
            FetchDescriptor<MyListCollectionItem>(
                sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
            )
        )
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
