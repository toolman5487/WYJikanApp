//
//  AnimeWatchProgressController.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/14.
//

import Foundation

struct AnimeWatchProgressUpdate {
    let status: AnimeWatchStatus
    let currentEpisode: Int?
    let totalEpisodes: Int?
}

struct AnimeWatchProgressController {

    // MARK: - Draft

    func editorDraft(
        for item: MyListItemSnapshot,
        anime: AnimeDetailDTO
    ) -> AnimeWatchProgressEditorDraft {
        AnimeWatchProgressEditorDraft(
            item: item,
            totalEpisodes: totalEpisodes(for: anime)
        )
    }

    // MARK: - Progress Update

    func incrementUpdate(
        for item: MyListItemSnapshot,
        anime: AnimeDetailDTO
    ) -> AnimeWatchProgressUpdate {
        let resolvedTotalEpisodes = totalEpisodes(for: anime)
        let nextEpisode = min(
            (item.currentEpisode ?? 0) + 1,
            resolvedTotalEpisodes ?? Int.max
        )
        let nextStatus: AnimeWatchStatus
        if let resolvedTotalEpisodes, nextEpisode >= resolvedTotalEpisodes {
            nextStatus = .completed
        } else {
            nextStatus = .watching
        }

        return AnimeWatchProgressUpdate(
            status: nextStatus,
            currentEpisode: nextEpisode,
            totalEpisodes: resolvedTotalEpisodes
        )
    }

    func decrementUpdate(
        for item: MyListItemSnapshot,
        anime: AnimeDetailDTO
    ) -> AnimeWatchProgressUpdate {
        let resolvedTotalEpisodes = totalEpisodes(for: anime)
        let nextEpisode = max((item.currentEpisode ?? 0) - 1, 0)
        let nextStatus: AnimeWatchStatus = nextEpisode > 0 ? .watching : .planned

        return AnimeWatchProgressUpdate(
            status: nextStatus,
            currentEpisode: nextEpisode,
            totalEpisodes: resolvedTotalEpisodes
        )
    }

    // MARK: - Private Methods

    private func totalEpisodes(for anime: AnimeDetailDTO) -> Int? {
        guard let episodes = anime.episodes, episodes > 0 else { return nil }
        return episodes
    }
}
