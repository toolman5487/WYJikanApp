//
//  AnimeBroadcastReminderReconciler.swift
//  WYJikanApp
//

import Foundation
import OSLog
import SwiftData

enum AnimeBroadcastReminderReconciler {
    @MainActor
    static func reconcile(
        anime: AnimeDetailDTO,
        isSubscribed: Bool,
        subscribedCount: Int,
        repository: any AnimeBroadcastReminderRepository,
        scheduler: HomeTodayAnimeNotificationScheduler,
        modelContext: ModelContext
    ) async {
        guard isSubscribed else { return }
        guard !AnimeBroadcastReminderScheduling.isCurrentlyAiring(anime) else { return }

        await unsubscribe(
            malId: anime.id,
            remainingSubscriptionCount: subscribedCount - 1,
            repository: repository,
            scheduler: scheduler,
            modelContext: modelContext
        )
    }

    @MainActor
    static func reconcileAll(
        subscriptions: [AnimeBroadcastReminderSnapshot],
        service: AnimeDetailServicing,
        repository: any AnimeBroadcastReminderRepository,
        scheduler: HomeTodayAnimeNotificationScheduler,
        modelContext: ModelContext
    ) async {
        guard !subscriptions.isEmpty else { return }

        var remainingCount = subscriptions.count

        for subscription in subscriptions {
            do {
                let response = try await service.fetchAnimeDetail(malId: subscription.malId)
                guard !AnimeBroadcastReminderScheduling.isCurrentlyAiring(response.data) else {
                    continue
                }

                try repository.unsubscribe(malId: subscription.malId, modelContext: modelContext)
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
        scheduler: HomeTodayAnimeNotificationScheduler,
        modelContext: ModelContext
    ) async {
        do {
            try repository.unsubscribe(malId: malId, modelContext: modelContext)
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
