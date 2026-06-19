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
        case loading
        case ready(ModelContainer)
        case failed(FeatureLoadFailure)
    }

    // MARK: - Properties

    @UIApplicationDelegateAdaptor(AppNotificationDelegate.self) private var appDelegate
    private let appDependencies = AppDependencies.live
    @State private var startupState: StartupState = .loading
    @State private var startupAttempt = 0
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
                .task(id: startupAttempt) {
                    await initializePersistence()
                }
        }
    }

    // MARK: - Private Views

    @ViewBuilder
    private var rootContent: some View {
        switch startupState {
        case .loading:
            AppLaunchLoadingView()
                .preferredColorScheme(.dark)
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
        case .failed(let failure):
            AppLaunchFailureView(
                failure: failure,
                onRetry: retryStartup
            )
                .preferredColorScheme(.dark)
        }
    }

    // MARK: - Private Methods

    private func initializePersistence() async {
        guard case .loading = startupState else { return }

        await Task.yield()
        guard !Task.isCancelled else { return }

        do {
            let modelContainer = try ModelContainer(
                for: MyListCollectionItem.self,
                AnimeBroadcastReminderSubscription.self
            )
            let modelContext = ModelContext(modelContainer)
            appDependencies.connectRepositories(modelContext: modelContext)
            favoriteStatusStore.connect(to: appDependencies.favoriteRepository)
            broadcastReminderStatusStore.connect(to: appDependencies.broadcastReminderRepository)
            startupState = .ready(modelContainer)
        } catch {
            AppLogger.persistence.error(
                "Failed to create model container: \(error.localizedDescription, privacy: .public)"
            )
            startupState = .failed(
                FeatureLoadFailure(
                    message: "收藏資料庫暫時無法啟動，請重新嘗試。若問題持續發生，請稍後再開啟 App。"
                )
            )
        }
    }

    private func retryStartup() {
        startupState = .loading
        startupAttempt += 1
    }
}

// MARK: - AppLaunchLoadingView

private struct AppLaunchLoadingView: View {

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(ThemeColor.sakura)

            Text("正在準備資料")
                .font(.headline)
                .foregroundStyle(ThemeColor.textPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .background(Color(.systemBackground))
    }
}

// MARK: - AppLaunchFailureView

private struct AppLaunchFailureView: View {

    // MARK: - Properties

    let failure: FeatureLoadFailure
    let onRetry: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            Text("App 暫時無法啟動")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(ThemeColor.textPrimary)

            ErrorMessageView(
                state: ErrorMessageView.State(failure: failure)
            )

            Button("重新嘗試", action: onRetry)
                .buttonStyle(.borderedProminent)
                .tint(ThemeColor.sakura)
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .background(Color(.systemBackground))
    }
}
