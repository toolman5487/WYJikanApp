//
//  MyListStatisticsScope.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import Foundation

enum MyListStatisticsScope: String, CaseIterable, Identifiable {
    case all
    case anime
    case manga

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "全部"
        case .anime:
            return "動畫"
        case .manga:
            return "漫畫"
        }
    }
}
