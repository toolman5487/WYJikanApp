//
//  WYJikanAppApp.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/24.
//

import SwiftUI
import SwiftData
import OSLog

@main
struct WYJikanAppApp: App {

    // MARK: - Properties

    @UIApplicationDelegateAdaptor(AppNotificationDelegate.self) private var appDelegate
    private let appDependencies = AppDependencies.live
    @State private var persistenceContainer: ModelContainer?
    @StateObject private var appPersistenceStore: AppPersistenceStore
    @StateObject private var favoriteStatusStore: FavoriteStatusStore
    @StateObject private var broadcastReminderStatusStore: AnimeBroadcastReminderStatusStore
    @StateObject private var todayAnimeNotificationScheduler: HomeTodayAnimeNotificationScheduler
    @StateObject private var appBootstrapViewModel: AppBootstrapViewModel
    @StateObject private var mainTabBarViewModel: MainTabBarViewModel
    @StateObject private var mainHomeRouter: MainHomeRouter

    // MARK: - Lifecycle

    init() {
        AppLaunchSignposter.beginColdLaunch()

        let favoriteStatusStore = FavoriteStatusStore()
        let broadcastReminderStatusStore = AnimeBroadcastReminderStatusStore()
        let appPersistenceStore = AppPersistenceStore()
        let todayAnimeNotificationScheduler = HomeTodayAnimeNotificationScheduler(
            subscriptionProvider: { broadcastReminderStatusStore.subscriptions }
        )
        let dependencies = AppDependencies.live
        let mainTabBarViewModel = MainTabBarViewModel()
        let mainHomeRouter = MainHomeRouter.shared

        _appPersistenceStore = StateObject(wrappedValue: appPersistenceStore)
        _favoriteStatusStore = StateObject(wrappedValue: favoriteStatusStore)
        _broadcastReminderStatusStore = StateObject(wrappedValue: broadcastReminderStatusStore)
        _todayAnimeNotificationScheduler = StateObject(wrappedValue: todayAnimeNotificationScheduler)
        _appBootstrapViewModel = StateObject(
            wrappedValue: AppBootstrapViewModel(
                animeDetailService: dependencies.animeDetailService,
                broadcastReminderRepository: dependencies.broadcastReminderRepository,
                notificationScheduler: todayAnimeNotificationScheduler,
                homeLoadCoordinator: dependencies.homeLoadCoordinator
            )
        )
        _mainTabBarViewModel = StateObject(wrappedValue: mainTabBarViewModel)
        _mainHomeRouter = StateObject(wrappedValue: mainHomeRouter)

        MainActor.assumeIsolated {
            AppNotificationDelegate.onNotificationOpened = { response in
                await todayAnimeNotificationScheduler.clearNotificationsForOpenedResponse(response)
            }
            AppNotificationDelegate.onRouteToHomeTab = {
                mainTabBarViewModel.selectedTab = .home
            }
            AppNotificationDelegate.onNavigateToMainHomeRoutes = { routes in
                mainHomeRouter.replacePath(with: routes)
            }
        }
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(\.appDependencies, appDependencies)
                .environmentObject(appPersistenceStore)
                .environmentObject(favoriteStatusStore)
                .environmentObject(broadcastReminderStatusStore)
                .environmentObject(todayAnimeNotificationScheduler)
                .environmentObject(appBootstrapViewModel)
                .environmentObject(mainTabBarViewModel)
                .environmentObject(mainHomeRouter)
                .task(id: appPersistenceStore.initializationAttempt) {
                    await initializePersistence()
                }
        }
    }

    // MARK: - Private Methods

    private func initializePersistence() async {
        guard case .initializing = appPersistenceStore.state else { return }

        await Task.yield()
        guard !Task.isCancelled else { return }

        AppLaunchSignposter.beginPersistenceInitialization()
        defer {
            AppLaunchSignposter.endPersistenceInitialization()
        }

        do {
            let modelContainer = try ModelContainer(
                for: MyListCollectionItem.self,
                AnimeBroadcastReminderSubscription.self
            )
            let modelContext = ModelContext(modelContainer)
            appDependencies.connectRepositories(modelContext: modelContext)
            favoriteStatusStore.connect(to: appDependencies.favoriteRepository)
            broadcastReminderStatusStore.connect(to: appDependencies.broadcastReminderRepository)
            persistenceContainer = modelContainer
            appPersistenceStore.markReady()
        } catch {
            AppLogger.persistence.error(
                "Failed to create model container: \(error.localizedDescription, privacy: .public)"
            )
            appPersistenceStore.markFailed(
                FeatureLoadFailure(
                    message: "收藏資料庫暫時無法啟動，請重新嘗試。若問題持續發生，請稍後再開啟 App。"
                )
            )
        }
    }
}
