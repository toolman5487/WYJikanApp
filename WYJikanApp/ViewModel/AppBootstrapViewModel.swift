//
//  AppBootstrapViewModel.swift
//  WYJikanApp
//

import Combine

// MARK: - HomeInitialLoadCoordinating

nonisolated protocol HomeInitialLoadCoordinating: Sendable {
    func waitForCompletion() async
    func markCompleted() async
}

// MARK: - HomeInitialLoadGate

actor HomeInitialLoadGate: HomeInitialLoadCoordinating {

    static let shared = HomeInitialLoadGate()

    private var isCompleted = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func waitForCompletion() async {
        guard !isCompleted else { return }

        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    func markCompleted() {
        guard !isCompleted else { return }
        isCompleted = true

        let pendingWaiters = waiters
        waiters.removeAll()
        pendingWaiters.forEach { $0.resume() }
    }
}

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
    private let homeInitialLoadGate: any HomeInitialLoadCoordinating

    // MARK: - Properties

    private var bootstrapState: BootstrapState = .idle

    // MARK: - Lifecycle

    init(
        animeDetailService: AnimeDetailServicing,
        broadcastReminderRepository: any AnimeBroadcastReminderRepository,
        notificationScheduler: HomeTodayAnimeNotificationScheduler,
        homeInitialLoadGate: any HomeInitialLoadCoordinating = HomeInitialLoadGate.shared
    ) {
        self.animeDetailService = animeDetailService
        self.broadcastReminderRepository = broadcastReminderRepository
        self.notificationScheduler = notificationScheduler
        self.homeInitialLoadGate = homeInitialLoadGate
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
            await homeInitialLoadGate.waitForCompletion()

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
