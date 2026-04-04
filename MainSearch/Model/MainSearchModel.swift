//
//  MainSearchModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/2.
//

import Foundation

// MARK: - Search Kind

enum MainSearchKind: String, CaseIterable, Hashable, Sendable {
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

    var searchPrompt: String {
        switch self {
        case .anime: return "搜尋動畫"
        case .manga: return "搜尋漫畫"
        case .character: return "搜尋角色"
        case .people: return "搜尋聲優"
        }
    }

    var jikanSearchPath: String {
        switch self {
        case .anime: return "anime"
        case .manga: return "manga"
        case .character: return "characters"
        case .people: return "people"
        }
    }
}
