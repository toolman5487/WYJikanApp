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
    @StateObject private var todayAnimeNotificationScheduler: HomeTodayAnimeNotificationScheduler

    init() {
        _todayAnimeNotificationScheduler = StateObject(
            wrappedValue: HomeTodayAnimeNotificationScheduler()
        )
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(todayAnimeNotificationScheduler)
        }
        .modelContainer(for: [MyListCollectionItem.self])
    }
}
