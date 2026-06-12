//
//  AnimeBroadcastReminderReconciler.swift
//  WYJikanApp
//

import Foundation
import OSLog

enum AnimeBroadcastReminderReconciler {
    private static let bootstrapDeferNanoseconds: UInt64 = 2_000_000_000
    private static let reconcileRequestIntervalNanoseconds: UInt64 = 1_000_000_000

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
        scheduler: HomeTodayAnimeNotificationScheduler
    ) async {
        guard !subscriptions.isEmpty else { return }

        try? await Task.sleep(nanoseconds: bootstrapDeferNanoseconds)
        if Task.isCancelled { return }

        var remainingCount = subscriptions.count

        for (index, subscription) in subscriptions.enumerated() {
            if index > 0 {
                try? await Task.sleep(nanoseconds: reconcileRequestIntervalNanoseconds)
                if Task.isCancelled { return }
            }

            do {
                let response = try await service.fetchAnimeDetail(malId: subscription.malId)
                guard !AnimeBroadcastReminderScheduling.isCurrentlyAiring(response.data) else {
                    continue
                }

                try repository.unsubscribe(malId: subscription.malId)
                await scheduler.removeReminders(forAnimeID: subscription.malId)
                remainingCount -= 1

                AppLogger.notifications.info(
                    "Removed inactive broadcast reminder subscription for animeID=\(subscription.malId, privacy: .public)"
                )
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
