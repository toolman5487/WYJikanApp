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
    @StateObject private var todayAnimeNotificationScheduler = HomeTodayAnimeNotificationScheduler.shared

    var body: some Scene {
        WindowGroup {
            MainTabBarView()
                .environmentObject(todayAnimeNotificationScheduler)
                .preferredColorScheme(.dark)
                .dynamicTypeSize(.medium)
                .task {
                    await todayAnimeNotificationScheduler.requestAuthorizationOnLaunchIfNeeded()
                    await todayAnimeNotificationScheduler.refreshScheduledNotificationIfNeeded()
                }
        }
        .modelContainer(for: [MyListCollectionItem.self])
    }
}
