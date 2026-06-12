//
//  MainTabBarViewModel.swift
//  WYJikanApp
//

import Combine
import Foundation

enum AppTab: Hashable {
    case home
    case categorylist
    case news
    case myList
    case searchLiquidGlass
}

@MainActor
final class MainTabBarViewModel: ObservableObject {

    // MARK: - Types

    private enum StorageKey {
        static let lastSeenMyListFavoriteCount = "mainTabBar.lastSeenMyListFavoriteCount"
    }

    // MARK: - Properties

    @Published var selectedTab: AppTab = .home
    @Published private(set) var lastSeenMyListFavoriteCount: Int

    private let storage: UserDefaults

    // MARK: - Lifecycle

    init(storage: UserDefaults = .standard) {
        self.storage = storage
        self.lastSeenMyListFavoriteCount = storage.integer(
            forKey: StorageKey.lastSeenMyListFavoriteCount
        )
    }

    // MARK: - Tab Selection

    func handleSelectedTabChange(_ tab: AppTab, favoriteCount: Int) {
        guard tab == .myList else { return }
        markMyListAsSeen(favoriteCount: favoriteCount)
    }

    // MARK: - My List Badge

    func handleFavoriteCountChange(_ favoriteCount: Int) {
        guard selectedTab == .myList else { return }
        markMyListAsSeen(favoriteCount: favoriteCount)
    }

    func myListBadgeCount(favoriteCount: Int) -> Int {
        max(0, favoriteCount - lastSeenMyListFavoriteCount)
    }

    // MARK: - Private Methods

    private func markMyListAsSeen(favoriteCount: Int) {
        guard lastSeenMyListFavoriteCount != favoriteCount else { return }
        lastSeenMyListFavoriteCount = favoriteCount
        storage.set(favoriteCount, forKey: StorageKey.lastSeenMyListFavoriteCount)
    }
}
