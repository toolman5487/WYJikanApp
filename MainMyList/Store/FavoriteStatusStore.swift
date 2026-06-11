//
//  FavoriteStatusStore.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/14.
//

import Foundation
import Combine
import OSLog
import SwiftData

@MainActor
final class FavoriteStatusStore: ObservableObject {
    @Published private(set) var animeFavoriteIDs: Set<Int> = []
    @Published private(set) var mangaFavoriteIDs: Set<Int> = []
    private var snapshotCancellable: AnyCancellable?

    func connect(
        to favoriteRepository: any FavoriteRepository,
        modelContext: ModelContext
    ) {
        guard snapshotCancellable == nil else { return }

        snapshotCancellable = favoriteRepository.favoriteSnapshotPublisher
            .sink { [weak self] snapshot in
                Task { [weak self] in
                    await MainActor.run {
                        self?.apply(snapshot: snapshot)
                    }
                }
            }

        do {
            try favoriteRepository.reloadFavorites(from: modelContext)
        } catch {
            AppLogger.persistence.error(
                "Favorite snapshot reload failed: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    init() {
    }

    func favoriteIDs(for mediaKind: MyListMediaKind) -> Set<Int> {
        switch mediaKind {
        case .anime:
            return animeFavoriteIDs
        case .manga:
            return mangaFavoriteIDs
        }
    }

    func isFavorite(malId: Int, mediaKind: MyListMediaKind) -> Bool {
        favoriteIDs(for: mediaKind).contains(malId)
    }

    var totalFavoriteCount: Int {
        animeFavoriteIDs.count + mangaFavoriteIDs.count
    }

    private func apply(snapshot: FavoriteSnapshot) {
        if animeFavoriteIDs != snapshot.animeIDs {
            animeFavoriteIDs = snapshot.animeIDs
        }
        if mangaFavoriteIDs != snapshot.mangaIDs {
            mangaFavoriteIDs = snapshot.mangaIDs
        }
    }
}

// MARK: - Broadcast Reminder

@MainActor
final class AnimeBroadcastReminderStatusStore: ObservableObject {
    @Published private(set) var subscriptions: [AnimeBroadcastReminderSnapshot] = []

    private var snapshotCancellable: AnyCancellable?

    func connect(
        to repository: any AnimeBroadcastReminderRepository,
        modelContext: ModelContext
    ) {
        guard snapshotCancellable == nil else { return }

        snapshotCancellable = repository.snapshotPublisher
            .sink { [weak self] snapshotSet in
                Task { @MainActor [weak self] in
                    self?.apply(snapshotSet: snapshotSet)
                }
            }

        do {
            try repository.reload(from: modelContext)
        } catch {
            AppLogger.persistence.error(
                "Broadcast reminder snapshot reload failed: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    func isSubscribed(malId: Int) -> Bool {
        subscriptions.contains { $0.malId == malId }
    }

    func navigationToolbarConfiguration(for anime: AnimeDetailDTO) -> DetailNavigationToolbarConfiguration {
        let reminderState = broadcastReminderState(for: anime)
        let layoutStyle: DetailNavigationToolbarLayoutStyle = reminderState == .hidden ? .expanded : .compact
        return DetailNavigationToolbarConfiguration(
            broadcastReminderState: reminderState,
            layoutStyle: layoutStyle
        )
    }

    private func broadcastReminderState(
        for anime: AnimeDetailDTO
    ) -> DetailNavigationToolbarBroadcastReminderState {
        if isSubscribed(malId: anime.id) {
            return .on
        }
        guard AnimeBroadcastReminderScheduling.canSubscribe(to: anime) else {
            return .hidden
        }
        return .off
    }

    private func apply(snapshotSet: AnimeBroadcastReminderSnapshotSet) {
        if subscriptions != snapshotSet.subscriptions {
            subscriptions = snapshotSet.subscriptions
        }
    }
}
