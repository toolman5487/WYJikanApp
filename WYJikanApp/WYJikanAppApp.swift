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
    @StateObject private var todayAnimeNotificationScheduler = HomeTodayAnimeNotificationScheduler.shared

    var body: some Scene {
        WindowGroup {
            MainTabBarView()
                .environmentObject(todayAnimeNotificationScheduler)
                .preferredColorScheme(.dark)
                .dynamicTypeSize(.medium)
                .task {
                    await todayAnimeNotificationScheduler.refreshScheduledNotificationIfNeeded()
                }
        }
        .modelContainer(for: [MyListCollectionItem.self])
    }
}
