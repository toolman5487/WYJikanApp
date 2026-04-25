//
//  MyListCollectionItem.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import Foundation
import SwiftData

enum MyListMediaKind: String, Codable, CaseIterable, Identifiable {
    case anime
    case manga

    var id: String { rawValue }

    var title: String {
        switch self {
        case .anime: return "動畫"
        case .manga: return "漫畫"
        }
    }

    var iconName: String {
        switch self {
        case .anime: return "play.rectangle.fill"
        case .manga: return "book.closed.fill"
        }
    }
}

@Model
final class MyListCollectionItem {
    var malId: Int
    var mediaKindRawValue: String
    var title: String
    var subtitle: String?
    var imageURLString: String?
    var addedAt: Date

    init(
        malId: Int,
        mediaKind: MyListMediaKind,
        title: String,
        subtitle: String?,
        imageURLString: String?,
        addedAt: Date
    ) {
        self.malId = malId
        self.mediaKindRawValue = mediaKind.rawValue
        self.title = title
        self.subtitle = subtitle
        self.imageURLString = imageURLString
        self.addedAt = addedAt
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
}
