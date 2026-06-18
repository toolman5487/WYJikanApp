//
//  SettingService.swift
//  WYJikanApp
//

import Combine
import Foundation
import SDWebImage

@MainActor
protocol SettingServicing: AnyObject {
    var searchHistoryCountPublisher: AnyPublisher<Int, Never> { get }

    func searchHistoryCount() -> Int
    func cacheSize() async -> Int64
    func clearCache() async throws
    func deleteLocalData(_ target: SettingLocalDataTarget) async throws
}

@MainActor
final class SettingService: SettingServicing {

    // MARK: - Dependencies

    private let historyRepository: any MainSearchHistoryRepository
    private let favoriteRepository: any FavoriteRepository
    private let broadcastReminderRepository: any AnimeBroadcastReminderRepository
    private let notificationScheduler: HomeTodayAnimeNotificationScheduler
    private let clearApplicationCache: () async -> Void

    // MARK: - Lifecycle

    init(
        historyRepository: any MainSearchHistoryRepository,
        favoriteRepository: any FavoriteRepository,
        broadcastReminderRepository: any AnimeBroadcastReminderRepository,
        notificationScheduler: HomeTodayAnimeNotificationScheduler,
        clearApplicationCache: @escaping () async -> Void
    ) {
        self.historyRepository = historyRepository
        self.favoriteRepository = favoriteRepository
        self.broadcastReminderRepository = broadcastReminderRepository
        self.notificationScheduler = notificationScheduler
        self.clearApplicationCache = clearApplicationCache
    }

    // MARK: - SettingServicing

    var searchHistoryCountPublisher: AnyPublisher<Int, Never> {
        historyRepository.historyPublisher
            .map(\.count)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func searchHistoryCount() -> Int {
        historyRepository.loadHistory().count
    }

    func cacheSize() async -> Int64 {
        let imageCacheSize = await imageDiskCacheSize()
        let urlCacheSize = URLCache.shared.currentDiskUsage
            + URLCache.shared.currentMemoryUsage
        return Int64(imageCacheSize) + Int64(urlCacheSize)
    }

    func clearCache() async throws {
        await clearApplicationCache()
        SDImageCache.shared.clearMemory()
        await clearImageDiskCache()
    }

    func deleteLocalData(_ target: SettingLocalDataTarget) async throws {
        switch target {
        case .searchHistory:
            deleteSearchHistory()
        case .broadcastReminders:
            try await deleteBroadcastReminders()
        case .favoritesAndProgress:
            try deleteFavoritesAndProgress()
        case .all:
            try await deleteAllLocalData()
        }
    }

    // MARK: - Local Data

    private func deleteSearchHistory() {
        _ = historyRepository.clearHistory()
    }

    private func deleteBroadcastReminders() async throws {
        try broadcastReminderRepository.removeAllSubscriptions()
        await notificationScheduler.handleSubscriptionsEmptied()
    }

    private func deleteFavoritesAndProgress() throws {
        try favoriteRepository.removeAllFavorites()
    }

    private func deleteAllLocalData() async throws {
        var hasCompletedOperation = false

        do {
            try await deleteBroadcastReminders()
            hasCompletedOperation = true
            try deleteFavoritesAndProgress()
            deleteSearchHistory()
        } catch {
            throw SettingLocalDataDeletionFailure(
                isPartiallyCompleted: hasCompletedOperation
            )
        }
    }

    // MARK: - Cache

    private func imageDiskCacheSize() async -> UInt {
        await withCheckedContinuation { continuation in
            SDImageCache.shared.calculateSize { _, totalSize in
                continuation.resume(returning: totalSize)
            }
        }
    }

    private func clearImageDiskCache() async {
        await withCheckedContinuation { continuation in
            SDImageCache.shared.clearDisk {
                continuation.resume()
            }
        }
    }
}
