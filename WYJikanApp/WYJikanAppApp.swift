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
    private enum StartupState {
        case ready(ModelContainer)
        case failed(message: String)
    }

    @UIApplicationDelegateAdaptor(AppNotificationDelegate.self) private var appDelegate
    private let startupState: StartupState
    @StateObject private var favoriteStatusStore: FavoriteStatusStore
    @StateObject private var todayAnimeNotificationScheduler: HomeTodayAnimeNotificationScheduler
    @StateObject private var mainTabBarViewModel: MainTabBarViewModel
    @StateObject private var mainHomeRouter: MainHomeRouter

    init() {
        let favoriteStatusStore = FavoriteStatusStore()
        let todayAnimeNotificationScheduler = HomeTodayAnimeNotificationScheduler()

        do {
            let sharedModelContainer = try ModelContainer(for: MyListCollectionItem.self)
            favoriteStatusStore.connect(
                to: SwiftDataFavoriteRepository.shared,
                modelContext: ModelContext(sharedModelContainer)
            )
            startupState = .ready(sharedModelContainer)
        } catch {
            AppLogger.persistence.error(
                "Failed to create model container: \(error.localizedDescription, privacy: .public)"
            )
            startupState = .failed(
                message: "收藏資料庫暫時無法啟動，請重新開啟 App。若問題持續發生，請稍後再試。"
            )
        }

        _favoriteStatusStore = StateObject(
            wrappedValue: favoriteStatusStore
        )
        _todayAnimeNotificationScheduler = StateObject(
            wrappedValue: todayAnimeNotificationScheduler
        )
        _mainTabBarViewModel = StateObject(
            wrappedValue: MainTabBarViewModel.shared
        )
        _mainHomeRouter = StateObject(
            wrappedValue: MainHomeRouter.shared
        )

        MainActor.assumeIsolated {
            AppNotificationDelegate.onNotificationOpened = { response in
                await todayAnimeNotificationScheduler.clearNotificationsForOpenedResponse(response)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            rootContent
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        switch startupState {
        case .ready(let modelContainer):
            AppRootView()
                .environmentObject(favoriteStatusStore)
                .environmentObject(todayAnimeNotificationScheduler)
                .environmentObject(mainTabBarViewModel)
                .environmentObject(mainHomeRouter)
                .modelContainer(modelContainer)
        case .failed(let message):
            AppLaunchFailureView(message: message)
                .preferredColorScheme(.dark)
        }
    }
}

private struct AppLaunchFailureView: View {
    let message: String

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
