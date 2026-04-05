//
//  MainListKind.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/5.
//

import Foundation

enum MainListKind: String, CaseIterable, Hashable, Sendable {
    case anime
    case manga
    case character
    case people

    var title: String {
        switch self {
        case .anime: return "動畫"
        case .manga: return "漫畫"
        case .character: return "角色"
        case .people: return "聲優"
        }
    }

    var jikanResourcePath: String {
        switch self {
        case .anime: return "anime"
        case .manga: return "manga"
        case .character: return "characters"
        case .people: return "people"
        }
    }
}
