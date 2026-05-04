//
//  HomeTodayAnimeScheduleListModel.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/5.
//

import Foundation

enum HomeScheduleDay: String, CaseIterable, Identifiable, Sendable {
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

struct HomeTodayAnimeResponse: Codable {
    let pagination: HomeTodayAnimePaginationDTO?
    let data: [HomeTodayAnimeDTO]
}

struct HomeTodayAnimePaginationDTO: Codable, Hashable, Sendable {
    let currentPage: Int?
    let hasNextPage: Bool?
    let lastVisiblePage: Int?
}

struct HomeTodayAnimeDTO: Codable, Identifiable, Hashable {
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

struct HomeTodayAnimeTimelineItem: Identifiable, Hashable, Sendable {
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

struct HomeTodayAnimeTimeSection: Identifiable, Hashable, Sendable {
    let title: String
    let items: [HomeTodayAnimeTimelineItem]

    var id: String { title }
}
