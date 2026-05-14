//
//  FavoriteStatusStore.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/14.
//

import Combine

@MainActor
final class FavoriteStatusStore: ObservableObject {
    @Published private(set) var animeFavoriteIDs: Set<Int> = []
    @Published private(set) var mangaFavoriteIDs: Set<Int> = []

    func sync(items: [MyListCollectionItem]) {
        var animeIDs: Set<Int> = []
        var mangaIDs: Set<Int> = []

        for item in items {
            switch item.mediaKind {
            case .anime:
                animeIDs.insert(item.malId)
            case .manga:
                mangaIDs.insert(item.malId)
            }
        }

        if animeFavoriteIDs != animeIDs {
            animeFavoriteIDs = animeIDs
        }
        if mangaFavoriteIDs != mangaIDs {
            mangaFavoriteIDs = mangaIDs
        }
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

    func applyFavoriteStatus(
        _ isFavorite: Bool,
        malId: Int,
        mediaKind: MyListMediaKind
    ) {
        switch mediaKind {
        case .anime:
            if isFavorite {
                animeFavoriteIDs.insert(malId)
            } else {
                animeFavoriteIDs.remove(malId)
            }
        case .manga:
            if isFavorite {
                mangaFavoriteIDs.insert(malId)
            } else {
                mangaFavoriteIDs.remove(malId)
            }
        }
    }
}
