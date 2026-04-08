//
//  MainListKind.swift
//  WYJikanApp
//
//

import Foundation

enum MainListKind: String, Hashable, CaseIterable, Sendable {
    case anime
    case manga
    case people
    case character

    static var categoryTags: [MainListKind] {
        [.anime, .manga, .people, .character]
    }

    var title: String {
        switch self {
        case .anime: return "動畫"
        case .manga: return "漫畫"
        case .people: return "聲優"
        case .character: return "角色"
        }
    }

    var jikanResourcePath: String {
        switch self {
        case .anime: return "anime"
        case .manga: return "manga"
        case .people: return "people"
        case .character: return "characters"
        }
    }
}

