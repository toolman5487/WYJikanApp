//
//  MyListMediaKind.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import Foundation

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
