//
//  AppRootView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/13.
//

import SwiftData
import SwiftUI

struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var broadcastReminderStatusStore: AnimeBroadcastReminderStatusStore
    @EnvironmentObject private var todayAnimeNotificationScheduler: HomeTodayAnimeNotificationScheduler

    var body: some View {
        MainTabBarView()
        .preferredColorScheme(.dark)
        .dynamicTypeSize(.medium)
        .task {
            await bootstrap()
        }
    }

    private func bootstrap() async {
        await AnimeBroadcastReminderReconciler.reconcileAll(
            subscriptions: broadcastReminderStatusStore.subscriptions,
            service: AnimeDetailService(),
            repository: SwiftDataAnimeBroadcastReminderRepository.shared,
            scheduler: todayAnimeNotificationScheduler,
            modelContext: modelContext
        )
        await todayAnimeNotificationScheduler.refreshScheduledNotificationIfNeeded()
    }
}

#Preview {
    AppRootView()
        .environmentObject(FavoriteStatusStore())
        .environmentObject(AnimeBroadcastReminderStatusStore())
        .environmentObject(HomeTodayAnimeNotificationScheduler())
        .environmentObject(MainTabBarViewModel.shared)
        .environmentObject(MainHomeRouter.shared)
}
