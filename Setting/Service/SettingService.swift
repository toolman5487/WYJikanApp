//
//  SettingService.swift
//  WYJikanApp
//

import Foundation

@MainActor
protocol SettingServicing: AnyObject {
    func searchHistoryCount() -> Int
    func clearSearchHistory()
    func clearFavorites() throws
    func clearCachedData() async
}

@MainActor
final class SettingService: SettingServicing {

    // MARK: - Dependencies

    private let dependencies: AppDependencies

    // MARK: - Lifecycle

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    // MARK: - SettingServicing

    func searchHistoryCount() -> Int {
        dependencies.mainSearchHistoryRepository.loadHistory().count
    }

    func clearSearchHistory() {
        _ = dependencies.mainSearchHistoryRepository.clearHistory()
    }

    func clearFavorites() throws {
        try dependencies.favoriteRepository.removeAllFavorites()
    }

    func clearCachedData() async {
        await dependencies.clearCachedData()
    }
}
