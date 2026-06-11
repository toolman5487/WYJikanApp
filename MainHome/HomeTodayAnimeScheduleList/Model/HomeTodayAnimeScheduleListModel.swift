//
//  HomeTodayAnimeScheduleListModel.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/5.
//

import Foundation
import SwiftData

nonisolated enum HomeScheduleDay: String, CaseIterable, Identifiable, Sendable {
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday

    var id: String { rawValue }

    var title: String {
        switch self {
        case .monday: return "週一"
        case .tuesday: return "週二"
        case .wednesday: return "週三"
        case .thursday: return "週四"
        case .friday: return "週五"
        case .saturday: return "週六"
        case .sunday: return "週日"
        }
    }

    var apiValue: String {
        rawValue
    }

    static func current(
        date: Date = Date(),
        calendar: Calendar = .current
    ) -> HomeScheduleDay {
        switch calendar.component(.weekday, from: date) {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .monday
        }
    }
}

nonisolated struct HomeTodayAnimeResponse: Codable, Sendable {
    let pagination: HomeTodayAnimePaginationDTO?
    let data: [HomeTodayAnimeDTO]
}

nonisolated struct HomeTodayAnimePaginationDTO: Codable, Hashable, Sendable {
    let currentPage: Int?
    let hasNextPage: Bool?
    let lastVisiblePage: Int?
}

nonisolated struct HomeTodayAnimeDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let title: String?
    let titleEnglish: String?
    let titleJapanese: String?
    let synopsis: String?
    let type: String?
    let score: Double?
    let episodes: Int?
    let status: String?
    let season: String?
    let year: Int?
    let broadcast: AnimeBroadcastDTO?
    let studios: [AnimeRelatedEntityDTO]?
    let images: AnimeImagesDTO?

    var id: Int { malId }
}

nonisolated struct HomeTodayAnimeTimelineItem: Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let typeText: String?
    let scoreText: String?
    let episodeText: String?
    let statusText: String?
    let studioText: String?
    let synopsisPreview: String?
    let imageURL: URL?
    let timeSectionTitle: String
    let timeSortValue: Int
    let broadcastText: String
}

nonisolated struct HomeTodayAnimeTimeSection: Identifiable, Hashable, Sendable {
    let title: String
    let items: [HomeTodayAnimeTimelineItem]

    var id: String { title }
}

// MARK: - Broadcast Reminder

@Model
final class AnimeBroadcastReminderSubscription {
    var malId: Int
    var title: String
    var broadcastDay: String?
    var broadcastTime: String?
    var broadcastTimezone: String?
    var broadcastString: String?
    var subscribedAt: Date

    init(
        malId: Int,
        title: String,
        broadcastDay: String?,
        broadcastTime: String?,
        broadcastTimezone: String?,
        broadcastString: String?,
        subscribedAt: Date
    ) {
        self.malId = malId
        self.title = title
        self.broadcastDay = broadcastDay
        self.broadcastTime = broadcastTime
        self.broadcastTimezone = broadcastTimezone
        self.broadcastString = broadcastString
        self.subscribedAt = subscribedAt
    }
}

nonisolated struct AnimeBroadcastReminderSnapshot: Identifiable, Hashable, Sendable {
    let malId: Int
    let title: String
    let broadcastDay: String?
    let broadcastTime: String?
    let broadcastTimezone: String?
    let broadcastString: String?

    var id: Int { malId }

    var broadcast: AnimeBroadcastDTO {
        AnimeBroadcastDTO(
            day: broadcastDay,
            time: broadcastTime,
            timezone: broadcastTimezone,
            string: broadcastString
        )
    }

    init(
        malId: Int,
        title: String,
        broadcastDay: String?,
        broadcastTime: String?,
        broadcastTimezone: String?,
        broadcastString: String?
    ) {
        self.malId = malId
        self.title = title
        self.broadcastDay = broadcastDay
        self.broadcastTime = broadcastTime
        self.broadcastTimezone = broadcastTimezone
        self.broadcastString = broadcastString
    }

    init(subscription: AnimeBroadcastReminderSubscription) {
        self.init(
            malId: subscription.malId,
            title: subscription.title,
            broadcastDay: subscription.broadcastDay,
            broadcastTime: subscription.broadcastTime,
            broadcastTimezone: subscription.broadcastTimezone,
            broadcastString: subscription.broadcastString
        )
    }

    init?(anime: AnimeDetailDTO, title: String) {
        guard AnimeBroadcastReminderScheduling.canSubscribe(to: anime) else {
            return nil
        }

        let broadcast = anime.broadcast
        self.init(
            malId: anime.id,
            title: title,
            broadcastDay: broadcast?.day,
            broadcastTime: broadcast?.time,
            broadcastTimezone: broadcast?.timezone,
            broadcastString: broadcast?.string
        )
    }
}

nonisolated struct AnimeBroadcastReminderSnapshotSet: Equatable, Sendable {
    let subscriptions: [AnimeBroadcastReminderSnapshot]

    var animeIDs: Set<Int> {
        Set(subscriptions.map(\.malId))
    }
}
