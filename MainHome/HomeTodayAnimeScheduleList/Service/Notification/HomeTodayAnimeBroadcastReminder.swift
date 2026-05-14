//
//  HomeTodayAnimeBroadcastReminder.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/9.
//

import Foundation

struct HomeTodayAnimeBroadcastReminder: Hashable {
    let animeID: Int
    let title: String
    let day: HomeScheduleDay
    let broadcastDate: Date
    let scheduledDate: Date
}
