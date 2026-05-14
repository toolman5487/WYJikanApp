//
//  WYJikanAppApp.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/24.
//

import SwiftUI
import SwiftData

@main
struct WYJikanAppApp: App {
    @UIApplicationDelegateAdaptor(AppNotificationDelegate.self) private var appDelegate
    private let modelContainer: ModelContainer
    @StateObject private var favoriteStatusStore: FavoriteStatusStore
    @StateObject private var todayAnimeNotificationScheduler: HomeTodayAnimeNotificationScheduler
    @StateObject private var mainTabBarViewModel: MainTabBarViewModel
    @StateObject private var mainHomeRouter: MainHomeRouter

    init() {
        let sharedModelContainer: ModelContainer
        do {
            sharedModelContainer = try ModelContainer(for: MyListCollectionItem.self)
        } catch {
            fatalError("Failed to create model container: \(error.localizedDescription)")
        }

        modelContainer = sharedModelContainer
        let favoriteStatusStore = FavoriteStatusStore()
        favoriteStatusStore.connect(
            to: SwiftDataFavoriteRepository.shared,
            modelContext: ModelContext(sharedModelContainer)
        )
        _favoriteStatusStore = StateObject(
            wrappedValue: favoriteStatusStore
        )
        _todayAnimeNotificationScheduler = StateObject(
            wrappedValue: HomeTodayAnimeNotificationScheduler()
        )
        _mainTabBarViewModel = StateObject(
            wrappedValue: MainTabBarViewModel.shared
        )
        _mainHomeRouter = StateObject(
            wrappedValue: MainHomeRouter.shared
        )
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(favoriteStatusStore)
                .environmentObject(todayAnimeNotificationScheduler)
                .environmentObject(mainTabBarViewModel)
                .environmentObject(mainHomeRouter)
        }
        .modelContainer(modelContainer)
    }
}
