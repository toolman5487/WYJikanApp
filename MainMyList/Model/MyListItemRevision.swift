//
//  MyListItemRevision.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/21.
//

import Foundation
import SwiftData

struct MyListItemRevision: Equatable {
    let id: PersistentIdentifier
    let malId: Int
    let mediaKindRawValue: String
    let title: String
    let subtitle: String?
    let imageURLString: String?
    let genreNamesRawValue: String?
    let type: String?
    let year: Int?
    let addedAt: Date
    let mangaReadingStatusRawValue: String?
    let currentChapter: Int?
    let totalChaptersSnapshot: Int?
    let progressUpdatedAt: Date?

    init(item: MyListCollectionItem) {
        id = item.persistentModelID
        malId = item.malId
        mediaKindRawValue = item.mediaKindRawValue
        title = item.title
        subtitle = item.subtitle
        imageURLString = item.imageURLString
        genreNamesRawValue = item.genreNamesRawValue
        type = item.type
        year = item.year
        addedAt = item.addedAt
        mangaReadingStatusRawValue = item.mangaReadingStatusRawValue
        currentChapter = item.currentChapter
        totalChaptersSnapshot = item.totalChaptersSnapshot
        progressUpdatedAt = item.progressUpdatedAt
    }
}

struct MyListItemsFingerprint: Equatable {
    private let count: Int
    private let digest: Int

    init(items: [MyListCollectionItem]) {
        count = items.count
        var hasher = Hasher()
        for item in items {
            hasher.combine(item.persistentModelID)
            hasher.combine(item.malId)
            hasher.combine(item.mediaKindRawValue)
            hasher.combine(item.title)
            hasher.combine(item.subtitle)
            hasher.combine(item.imageURLString)
            hasher.combine(item.genreNamesRawValue)
            hasher.combine(item.type)
            hasher.combine(item.year)
            hasher.combine(item.addedAt)
            hasher.combine(item.mangaReadingStatusRawValue)
            hasher.combine(item.currentChapter)
            hasher.combine(item.totalChaptersSnapshot)
            hasher.combine(item.progressUpdatedAt)
        }
        digest = hasher.finalize()
    }
}
