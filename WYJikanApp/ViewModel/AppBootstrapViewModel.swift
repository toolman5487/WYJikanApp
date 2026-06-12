//
//  AppBootstrapViewModel.swift
//  WYJikanApp
//

import Combine

@MainActor
final class AppBootstrapViewModel: ObservableObject {

    // MARK: - Dependencies

    private let animeDetailService: AnimeDetailServicing
    private let broadcastReminderRepository: any AnimeBroadcastReminderRepository
    private let notificationScheduler: HomeTodayAnimeNotificationScheduler

    // MARK: - Lifecycle

    init(
        animeDetailService: AnimeDetailServicing,
        broadcastReminderRepository: any AnimeBroadcastReminderRepository,
        notificationScheduler: HomeTodayAnimeNotificationScheduler
    ) {
        self.animeDetailService = animeDetailService
        self.broadcastReminderRepository = broadcastReminderRepository
        self.notificationScheduler = notificationScheduler
    }

    // MARK: - Public Methods

    func bootstrap(subscriptions: [AnimeBroadcastReminderSnapshot]) async {
        await Task(priority: .utility) {
            await AnimeBroadcastReminderReconciler.reconcileAll(
                subscriptions: subscriptions,
                service: animeDetailService,
                repository: broadcastReminderRepository,
                scheduler: notificationScheduler
            )
            await notificationScheduler.refreshScheduledNotificationIfNeeded()
        }.value
    }
}
