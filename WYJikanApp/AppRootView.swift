//
//  AppRootView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/13.
//

import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var bootstrapViewModel: AppBootstrapViewModel

    var body: some View {
        MainTabBarView()
        .preferredColorScheme(.dark)
        .onAppear {
            AppLaunchSignposter.markAppRootVisible()
        }
        .task(priority: .utility) {
            await bootstrapViewModel.bootstrap()
        }
    }
}

#Preview {
    AppRootView()
        .environment(\.appDependencies, .live)
        .environmentObject(FavoriteStatusStore())
        .environmentObject(AnimeBroadcastReminderStatusStore())
        .environmentObject(HomeTodayAnimeNotificationScheduler())
        .environmentObject(
            AppBootstrapViewModel(
                animeDetailService: AppDependencies.live.animeDetailService,
                broadcastReminderRepository: AppDependencies.live.broadcastReminderRepository,
                notificationScheduler: HomeTodayAnimeNotificationScheduler()
            )
        )
        .environmentObject(MainTabBarViewModel())
        .environmentObject(MainHomeRouter.shared)
}
