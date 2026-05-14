//
//  FavoriteRepository.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/14.
//

import Foundation
import SwiftData

protocol FavoriteRepository {
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

struct SwiftDataFavoriteRepository: FavoriteRepository {
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
        } catch {
            modelContext.rollback()
            throw error
        }
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
