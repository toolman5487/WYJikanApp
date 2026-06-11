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
}
