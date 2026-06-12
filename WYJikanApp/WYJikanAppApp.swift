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

    // MARK: - Types

    private enum StartupState {
        case ready(ModelContainer)
        case failed(message: String)
    }

    // MARK: - Properties

    @UIApplicationDelegateAdaptor(AppNotificationDelegate.self) private var appDelegate
    private let appDependencies = AppDependencies.live
    private let startupState: StartupState
    @StateObject private var favoriteStatusStore: FavoriteStatusStore
    @StateObject private var broadcastReminderStatusStore: AnimeBroadcastReminderStatusStore
    @StateObject private var todayAnimeNotificationScheduler: HomeTodayAnimeNotificationScheduler
    @StateObject private var appBootstrapViewModel: AppBootstrapViewModel
    @StateObject private var mainTabBarViewModel: MainTabBarViewModel
    @StateObject private var mainHomeRouter: MainHomeRouter

    // MARK: - Lifecycle

    init() {
        let favoriteStatusStore = FavoriteStatusStore()
        let broadcastReminderStatusStore = AnimeBroadcastReminderStatusStore()
        let todayAnimeNotificationScheduler = HomeTodayAnimeNotificationScheduler(
            subscriptionProvider: { broadcastReminderStatusStore.subscriptions }
        )
        let dependencies = AppDependencies.live
        let mainTabBarViewModel = MainTabBarViewModel()
        let mainHomeRouter = MainHomeRouter.shared

        do {
            let sharedModelContainer = try ModelContainer(
                for: MyListCollectionItem.self,
                AnimeBroadcastReminderSubscription.self
            )
            let modelContext = ModelContext(sharedModelContainer)
            dependencies.connectRepositories(modelContext: modelContext)
            favoriteStatusStore.connect(to: dependencies.favoriteRepository)
            broadcastReminderStatusStore.connect(to: dependencies.broadcastReminderRepository)
            startupState = .ready(sharedModelContainer)
        } catch {
            AppLogger.persistence.error(
                "Failed to create model container: \(error.localizedDescription, privacy: .public)"
            )
            startupState = .failed(
                message: "收藏資料庫暫時無法啟動，請重新開啟 App。若問題持續發生，請稍後再試。"
            )
        }

        _favoriteStatusStore = StateObject(wrappedValue: favoriteStatusStore)
        _broadcastReminderStatusStore = StateObject(wrappedValue: broadcastReminderStatusStore)
        _todayAnimeNotificationScheduler = StateObject(wrappedValue: todayAnimeNotificationScheduler)
        _appBootstrapViewModel = StateObject(
            wrappedValue: AppBootstrapViewModel(
                animeDetailService: dependencies.animeDetailService,
                broadcastReminderRepository: dependencies.broadcastReminderRepository,
                notificationScheduler: todayAnimeNotificationScheduler
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
            rootContent
        }
    }

    // MARK: - Private Views

    @ViewBuilder
    private var rootContent: some View {
        switch startupState {
        case .ready(let modelContainer):
            AppRootView()
                .environment(\.appDependencies, appDependencies)
                .environmentObject(favoriteStatusStore)
                .environmentObject(broadcastReminderStatusStore)
                .environmentObject(todayAnimeNotificationScheduler)
                .environmentObject(appBootstrapViewModel)
                .environmentObject(mainTabBarViewModel)
                .environmentObject(mainHomeRouter)
                .modelContainer(modelContainer)
        case .failed(let message):
            AppLaunchFailureView(message: message)
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - AppLaunchFailureView

private struct AppLaunchFailureView: View {

    // MARK: - Properties

    let message: String

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(ThemeColor.sakura)

            Text("App 暫時無法啟動")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(ThemeColor.textPrimary)

            Text(message)
                .font(.body)
                .foregroundStyle(ThemeColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .background(Color(.systemBackground))
    }
}
