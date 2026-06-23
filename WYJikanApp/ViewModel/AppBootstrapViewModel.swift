//
//  AppBootstrapViewModel.swift
//  WYJikanApp
//

import Combine

// MARK: - AppBootstrapViewModel

@MainActor
final class AppBootstrapViewModel: ObservableObject {

    // MARK: - Types

    private enum BootstrapState {
        case idle
        case running
        case completed
    }

    // MARK: - Dependencies

    private let animeDetailService: AnimeDetailServicing
    private let broadcastReminderRepository: any AnimeBroadcastReminderRepository
    private let notificationScheduler: HomeTodayAnimeNotificationScheduler
    private let homeLoadCoordinator: any HomeLoadCoordinating

    // MARK: - Properties

    private var bootstrapState: BootstrapState = .idle

    // MARK: - Lifecycle

    init(
        animeDetailService: AnimeDetailServicing,
        broadcastReminderRepository: any AnimeBroadcastReminderRepository,
        notificationScheduler: HomeTodayAnimeNotificationScheduler,
        homeLoadCoordinator: any HomeLoadCoordinating = HomeLoadCoordinator.shared
    ) {
        self.animeDetailService = animeDetailService
        self.broadcastReminderRepository = broadcastReminderRepository
        self.notificationScheduler = notificationScheduler
        self.homeLoadCoordinator = homeLoadCoordinator
    }

    // MARK: - Public Methods

    func bootstrap() async {
        guard bootstrapState == .idle else { return }
        bootstrapState = .running
        AppLaunchSignposter.beginBootstrap()
        defer {
            AppLaunchSignposter.endBootstrap()
        }

        let subscriptions = broadcastReminderRepository.currentSnapshot.subscriptions

        if !subscriptions.isEmpty {
            await homeLoadCoordinator.wait(for: .allFeeds)

            guard !Task.isCancelled else {
                bootstrapState = .idle
                return
            }

            await AnimeBroadcastReminderReconciler.reconcileAll(
                subscriptions: subscriptions,
                service: animeDetailService,
                repository: broadcastReminderRepository,
                scheduler: notificationScheduler
            )
        }

        guard !Task.isCancelled else {
            bootstrapState = .idle
            return
        }

        await notificationScheduler.refreshScheduledNotificationIfNeeded()
        bootstrapState = .completed
    }
}
