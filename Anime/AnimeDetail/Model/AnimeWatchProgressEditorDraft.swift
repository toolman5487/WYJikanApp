//
//  AnimeWatchProgressEditorDraft.swift
//  WYJikanApp
//

import Foundation

struct AnimeWatchProgressEditorDraft: Identifiable {
    let id = UUID()
    let totalEpisodes: Int?
    var status: AnimeWatchStatus
    var currentEpisode: Int

    init(
        item: MyListItemSnapshot,
        totalEpisodes: Int?
    ) {
        self.totalEpisodes = totalEpisodes ?? item.totalEpisodes
        self.status = item.animeWatchStatus
        self.currentEpisode = item.currentEpisode ?? 0
    }
}
