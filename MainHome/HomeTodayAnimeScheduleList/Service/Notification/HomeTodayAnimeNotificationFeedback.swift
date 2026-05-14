//
//  HomeTodayAnimeNotificationFeedback.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/9.
//

import Foundation

struct HomeTodayAnimeNotificationFeedback: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

enum HomeTodayAnimeNotificationFeedbackMessage {
    static func enabled(scheduledCount: Int) -> String {
        if scheduledCount == 0 {
            return "會依你的本機時區，在動畫播出時通知。目前沒有可排程作品，之後開啟 App 時會自動更新。"
        }

        if scheduledCount >= HomeTodayAnimeNotificationConfig.maxScheduledNotifications {
            return "會依你的本機時區，在動畫播出時通知。目前先安排最近 \(scheduledCount) 則，之後開啟 App 時會刷新下一批。"
        }

        return "會依你的本機時區，在動畫播出時通知。目前已安排 \(scheduledCount) 則通知。"
    }
}
