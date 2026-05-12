//
//  WYJikanAppApp.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/24.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct WYJikanAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
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

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
