//
//  AnimeBroadcastReminderReconciler.swift
//  WYJikanApp
//

import Foundation
import OSLog

// MARK: - AnimeBroadcastReminderReconciliationTracking

@MainActor
protocol AnimeBroadcastReminderReconciliationTracking: AnyObject {
    func subscriptionsRequiringCheck(
        from subscriptions: [AnimeBroadcastReminderSnapshot]
    ) -> [AnimeBroadcastReminderSnapshot]
    func recordSuccessfulCheck(forAnimeID animeID: Int)
    func removeCheck(forAnimeID animeID: Int)
}

// MARK: - UserDefaultsAnimeBroadcastReminderReconciliationTracker

@MainActor
final class UserDefaultsAnimeBroadcastReminderReconciliationTracker:
    AnimeBroadcastReminderReconciliationTracking {

    static let shared = UserDefaultsAnimeBroadcastReminderReconciliationTracker()

    private struct Entry: Codable {
        let animeID: Int
        let checkedAt: Date
    }

    private let userDefaults: UserDefaults
    private let now: () -> Date

    init(
        userDefaults: UserDefaults = .standard,
        now: @escaping () -> Date = Date.init
    ) {
        self.userDefaults = userDefaults
        self.now = now
    }

    func subscriptionsRequiringCheck(
        from subscriptions: [AnimeBroadcastReminderSnapshot]
    ) -> [AnimeBroadcastReminderSnapshot] {
        let currentDate = now()
        let expirationDate = currentDate.addingTimeInterval(
            -HomeTodayAnimeNotificationConfig.reconciliationCheckInterval
        )
        let subscribedAnimeIDs = Set(subscriptions.map(\.malId))
        let retainedEntries = loadEntries().filter { animeID, checkedAt in
            subscribedAnimeIDs.contains(animeID) && checkedAt > expirationDate
        }
        saveEntries(retainedEntries)

        return subscriptions.filter { subscription in
            retainedEntries[subscription.malId] == nil
        }
    }

    func recordSuccessfulCheck(forAnimeID animeID: Int) {
        var entries = loadEntries()
        entries[animeID] = now()
        saveEntries(entries)
    }

    func removeCheck(forAnimeID animeID: Int) {
        var entries = loadEntries()
        entries.removeValue(forKey: animeID)
        saveEntries(entries)
    }

    private func loadEntries() -> [Int: Date] {
        guard let data = userDefaults.data(
            forKey: HomeTodayAnimeNotificationConfig.reconciliationCheckDatesKey
        ),
        let entries = try? JSONDecoder().decode([Entry].self, from: data) else {
            return [:]
        }

        return Dictionary(
            entries.map { ($0.animeID, $0.checkedAt) },
            uniquingKeysWith: { _, latest in latest }
        )
    }

    private func saveEntries(_ entries: [Int: Date]) {
        let values = entries
            .map { Entry(animeID: $0.key, checkedAt: $0.value) }
            .sorted { $0.animeID < $1.animeID }
        guard let data = try? JSONEncoder().encode(values) else { return }
        userDefaults.set(
            data,
            forKey: HomeTodayAnimeNotificationConfig.reconciliationCheckDatesKey
        )
    }
}

// MARK: - AnimeBroadcastReminderReconciler

enum AnimeBroadcastReminderReconciler {

    // MARK: - Constants

    private static let reconcileRequestIntervalNanoseconds: UInt64 = 1_000_000_000

    // MARK: - Public Methods

    @MainActor
    static func reconcile(
        anime: AnimeDetailDTO,
        isSubscribed: Bool,
        subscribedCount: Int,
        repository: any AnimeBroadcastReminderRepository,
        scheduler: HomeTodayAnimeNotificationScheduler
    ) async {
        guard isSubscribed else { return }
        guard !AnimeBroadcastReminderScheduling.isCurrentlyAiring(anime) else { return }

        await unsubscribe(
            malId: anime.id,
            remainingSubscriptionCount: subscribedCount - 1,
            repository: repository,
            scheduler: scheduler
        )
    }

    @MainActor
    static func reconcileAll(
        subscriptions: [AnimeBroadcastReminderSnapshot],
        service: AnimeDetailServicing,
        repository: any AnimeBroadcastReminderRepository,
        scheduler: HomeTodayAnimeNotificationScheduler,
        reconciliationTracker: any AnimeBroadcastReminderReconciliationTracking =
            UserDefaultsAnimeBroadcastReminderReconciliationTracker.shared
    ) async {
        guard !subscriptions.isEmpty else { return }

        let subscriptionsToCheck = reconciliationTracker.subscriptionsRequiringCheck(
            from: subscriptions
        )
        let skippedCount = subscriptions.count - subscriptionsToCheck.count
        if skippedCount > 0 {
            AppLogger.notifications.debug(
                "Skipped recent broadcast reminder reconciliation checks count=\(skippedCount, privacy: .public)"
            )
        }
        guard !subscriptionsToCheck.isEmpty else { return }

        var remainingCount = subscriptions.count

        for (index, subscription) in subscriptionsToCheck.enumerated() {
            if index > 0 {
                try? await Task.sleep(nanoseconds: reconcileRequestIntervalNanoseconds)
                if Task.isCancelled { return }
            }

            do {
                let response = try await service.fetchAnimeDetail(malId: subscription.malId)
                if AnimeBroadcastReminderScheduling.isCurrentlyAiring(response.data) {
                    reconciliationTracker.recordSuccessfulCheck(forAnimeID: subscription.malId)
                    continue
                }

                try repository.unsubscribe(malId: subscription.malId)
                reconciliationTracker.removeCheck(forAnimeID: subscription.malId)
                await scheduler.removeReminders(forAnimeID: subscription.malId)
                remainingCount -= 1

                AppLogger.notifications.info(
                    "Removed inactive broadcast reminder subscription for animeID=\(subscription.malId, privacy: .public)"
                )
            } catch JikanAPIError.rateLimited(let retryAfter) {
                let pendingCount = subscriptionsToCheck.count - index - 1
                AppLogger.notifications.warning(
                    "Broadcast reminder reconciliation paused after rate limit for animeID=\(subscription.malId, privacy: .public), retry after \(retryAfter, format: .fixed(precision: 1)) seconds, pending=\(pendingCount, privacy: .public)"
                )
                break
            } catch {
                AppLogger.notifications.warning(
                    "Inactive broadcast reminder reconciliation skipped for animeID=\(subscription.malId, privacy: .public): \(error.localizedDescription, privacy: .public)"
                )
            }
        }

        guard remainingCount < subscriptions.count else { return }

        if remainingCount == 0 {
            await scheduler.handleSubscriptionsEmptied()
        } else {
            await scheduler.refreshScheduledNotificationsImmediately()
        }
    }

    @MainActor
    static func unsubscribe(
        malId: Int,
        remainingSubscriptionCount: Int,
        repository: any AnimeBroadcastReminderRepository,
        scheduler: HomeTodayAnimeNotificationScheduler
    ) async {
        do {
            try repository.unsubscribe(malId: malId)
            await scheduler.removeReminders(forAnimeID: malId)

            if remainingSubscriptionCount <= 0 {
                await scheduler.handleSubscriptionsEmptied()
            } else {
                await scheduler.refreshScheduledNotificationsImmediately()
            }
        } catch {
            AppLogger.persistence.error(
                "Broadcast reminder unsubscribe failed for animeID=\(malId, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
        }
    }
}
