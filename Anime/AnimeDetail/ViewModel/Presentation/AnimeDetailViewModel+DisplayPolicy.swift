//
//  AnimeDetailViewModel+DisplayPolicy.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

import Foundation

extension AnimeDetailViewModel {

    // MARK: - Media Kind

    func mediaKind(for anime: AnimeDetailDTO) -> AnimeDetailMediaKind {
        AnimeDetailMediaKind(anime: anime)
    }

    // MARK: - Basic Info Rows

    func weeklyBroadcastRowTitle(for anime: AnimeDetailDTO) -> String {
        switch mediaKind(for: anime) {
        case .movie:
            return "上映／放映"
        case .music:
            return "發行／播出"
        default:
            return "播出時間"
        }
    }
}
