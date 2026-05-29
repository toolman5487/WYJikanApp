//
//  AppNotificationDelegate.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/12.
//

import UIKit
import UserNotifications

final class AppNotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    @MainActor
    static var onNotificationOpened: (@MainActor (UNNotificationResponse) async -> Void)?

    private enum NotificationUserInfoKey {
        static let route = "route"
        static let animeID = "animeID"
    }

    private enum NotificationRoute: String {
        case todayAnimeSchedule
    }

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

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        await Self.onNotificationOpened?(response)

        let userInfo = response.notification.request.content.userInfo
        guard let routeValue = userInfo[NotificationUserInfoKey.route] as? String,
              let route = NotificationRoute(rawValue: routeValue) else {
            return
        }

        await MainActor.run {
            switch route {
            case .todayAnimeSchedule:
                routeToTodayAnimeSchedule(using: userInfo)
            }
        }
    }

    @MainActor
    private func routeToTodayAnimeSchedule(using userInfo: [AnyHashable: Any]) {
        MainTabBarViewModel.shared.selectedTab = .home

        let routes: [MainHomeRoute]
        if let animeID = userInfo[NotificationUserInfoKey.animeID] as? Int {
            routes = [
                .todayAnimeSchedule,
                .animeDetail(malId: animeID)
            ]
        } else {
            routes = [.todayAnimeSchedule]
        }

        MainHomeRouter.shared.replacePath(with: routes)
    }
}
