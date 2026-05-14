//
//  AppRootView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/13.
//

import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var todayAnimeNotificationScheduler: HomeTodayAnimeNotificationScheduler

    var body: some View {
        ZStack {
            MainTabBarView()
            FavoriteStatusSyncBridge()
        }
        .preferredColorScheme(.dark)
        .dynamicTypeSize(.medium)
        .task {
            await bootstrap()
        }
    }

    private func bootstrap() async {
        await todayAnimeNotificationScheduler.requestAuthorizationOnLaunchIfNeeded()
        await todayAnimeNotificationScheduler.refreshScheduledNotificationIfNeeded()
    }
}

#Preview {
    AppRootView()
        .environmentObject(FavoriteStatusStore())
        .environmentObject(HomeTodayAnimeNotificationScheduler())
}
