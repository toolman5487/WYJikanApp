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

// MARK: - Broadcast Reminder

protocol AnimeBroadcastReminderRepository: AnyObject {
    var snapshotPublisher: AnyPublisher<AnimeBroadcastReminderSnapshotSet, Never> { get }

    func reload(from modelContext: ModelContext) throws

    func subscribe(
        snapshot: AnimeBroadcastReminderSnapshot,
        modelContext: ModelContext
    ) throws

    func unsubscribe(
        malId: Int,
        modelContext: ModelContext
    ) throws
}

final class SwiftDataAnimeBroadcastReminderRepository: AnimeBroadcastReminderRepository {
    static let shared = SwiftDataAnimeBroadcastReminderRepository()

    var snapshotPublisher: AnyPublisher<AnimeBroadcastReminderSnapshotSet, Never> {
        snapshotSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private let snapshotSubject = CurrentValueSubject<AnimeBroadcastReminderSnapshotSet, Never>(
        AnimeBroadcastReminderSnapshotSet(subscriptions: [])
    )

    private init() {}

    func reload(from modelContext: ModelContext) throws {
        snapshotSubject.send(try makeSnapshotSet(from: modelContext))
    }

    func subscribe(
        snapshot: AnimeBroadcastReminderSnapshot,
        modelContext: ModelContext
    ) throws {
        if let existing = try fetchSubscription(malId: snapshot.malId, modelContext: modelContext) {
            existing.title = snapshot.title
            existing.broadcastDay = snapshot.broadcastDay
            existing.broadcastTime = snapshot.broadcastTime
            existing.broadcastTimezone = snapshot.broadcastTimezone
            existing.broadcastString = snapshot.broadcastString
        } else {
            modelContext.insert(
                AnimeBroadcastReminderSubscription(
                    malId: snapshot.malId,
                    title: snapshot.title,
                    broadcastDay: snapshot.broadcastDay,
                    broadcastTime: snapshot.broadcastTime,
                    broadcastTimezone: snapshot.broadcastTimezone,
                    broadcastString: snapshot.broadcastString,
                    subscribedAt: Date()
                )
            )
        }

        try modelContext.save()
        try publish(from: modelContext)
    }

    func unsubscribe(
        malId: Int,
        modelContext: ModelContext
    ) throws {
        guard let existing = try fetchSubscription(malId: malId, modelContext: modelContext) else {
            return
        }

        modelContext.delete(existing)

        do {
            try modelContext.save()
            try publish(from: modelContext)
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    private func publish(from modelContext: ModelContext) throws {
        snapshotSubject.send(try makeSnapshotSet(from: modelContext))
    }

    private func makeSnapshotSet(from modelContext: ModelContext) throws -> AnimeBroadcastReminderSnapshotSet {
        let subscriptions = try modelContext.fetch(
            FetchDescriptor<AnimeBroadcastReminderSubscription>(
                sortBy: [SortDescriptor(\.subscribedAt, order: .reverse)]
            )
        )
        return AnimeBroadcastReminderSnapshotSet(
            subscriptions: subscriptions.map(AnimeBroadcastReminderSnapshot.init(subscription:))
        )
    }

    private func fetchSubscription(
        malId: Int,
        modelContext: ModelContext
    ) throws -> AnimeBroadcastReminderSubscription? {
        var descriptor = FetchDescriptor<AnimeBroadcastReminderSubscription>(
            predicate: #Predicate<AnimeBroadcastReminderSubscription> {
                $0.malId == malId
            }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}
