//
//  AppRootView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/13.
//

import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var bootstrapViewModel: AppBootstrapViewModel
    @EnvironmentObject private var appPersistenceStore: AppPersistenceStore

    var body: some View {
        MainTabBarView()
        .preferredColorScheme(.dark)
        .onAppear {
            AppLaunchSignposter.markAppRootVisible()
        }
        .task(id: appPersistenceStore.isReady, priority: .utility) {
            guard appPersistenceStore.isReady else { return }
            await bootstrapViewModel.bootstrap()
        }
    }
}

#Preview {
    AppRootView()
        .environment(\.appDependencies, .live)
        .environmentObject(AppPersistenceStore())
        .environmentObject(FavoriteStatusStore())
        .environmentObject(AnimeBroadcastReminderStatusStore())
        .environmentObject(HomeTodayAnimeNotificationScheduler())
        .environmentObject(
            AppBootstrapViewModel(
                animeDetailService: AppDependencies.live.animeDetailService,
                broadcastReminderRepository: AppDependencies.live.broadcastReminderRepository,
                notificationScheduler: HomeTodayAnimeNotificationScheduler(),
                homeLoadCoordinator: AppDependencies.live.homeLoadCoordinator
            )
        )
        .environmentObject(MainTabBarViewModel())
        .environmentObject(MainHomeRouter.shared)
}
