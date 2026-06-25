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

    private let backgroundAnimeDetailService: AnimeDetailServicing
    private let broadcastReminderRepository: any AnimeBroadcastReminderRepository
    private let notificationScheduler: HomeTodayAnimeNotificationScheduler
    private let homeFeedBootstrapCoordinator: any HomeFeedBootstrapCoordinating

    // MARK: - Properties

    private var bootstrapState: BootstrapState = .idle

    // MARK: - Lifecycle

    init(
        backgroundAnimeDetailService: AnimeDetailServicing,
        broadcastReminderRepository: any AnimeBroadcastReminderRepository,
        notificationScheduler: HomeTodayAnimeNotificationScheduler,
        homeFeedBootstrapCoordinator: any HomeFeedBootstrapCoordinating
    ) {
        self.backgroundAnimeDetailService = backgroundAnimeDetailService
        self.broadcastReminderRepository = broadcastReminderRepository
        self.notificationScheduler = notificationScheduler
        self.homeFeedBootstrapCoordinator = homeFeedBootstrapCoordinator
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
            await homeFeedBootstrapCoordinator.wait(for: .allFeedsReady)

            guard !Task.isCancelled else {
                bootstrapState = .idle
                return
            }

            await AnimeBroadcastReminderReconciler.reconcileAll(
                subscriptions: subscriptions,
                service: backgroundAnimeDetailService,
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
