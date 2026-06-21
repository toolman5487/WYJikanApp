//
//  MyListFilter.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import Foundation

nonisolated enum MyListFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case anime
    case manga

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "全部"
        case .anime: return "動畫"
        case .manga: return "漫畫"
        }
    }

    var mediaKind: MyListMediaKind? {
        switch self {
        case .all: return nil
        case .anime: return .anime
        case .manga: return .manga
        }
    }
}
