//
//  AnimeWatchStatusQueryModel.swift
//  WYJikanApp
//

import Foundation

// MARK: - AnimeWatchStatusFilter

enum AnimeWatchStatusFilter: Hashable, Identifiable, Sendable {
    case all
    case status(AnimeWatchStatus)

    var id: String {
        switch self {
        case .all:
            return "all"
        case .status(let status):
            return status.rawValue
        }
    }

    var title: String {
        switch self {
        case .all:
            return "全部"
        case .status(let status):
            return status.title
        }
    }

    var systemImageName: String {
        switch self {
        case .all:
            return "play.rectangle"
        case .status(let status):
            return status.systemImageName
        }
    }

    static let allCases: [AnimeWatchStatusFilter] = [
        .all,
        .status(.planned),
        .status(.watching),
        .status(.onHold),
        .status(.completed),
        .status(.dropped)
    ]
}

// MARK: - AnimeWatchStatusCount

struct AnimeWatchStatusCount: Identifiable, Sendable {
    let filter: AnimeWatchStatusFilter
    let count: Int

    var id: String { filter.id }
}

// MARK: - AnimeWatchStatusSummary

struct AnimeWatchStatusSummary: Sendable {
    let totalCount: Int
    let watchingCount: Int
    let plannedCount: Int
    let completedCount: Int
    let statusCounts: [AnimeWatchStatusCount]

    static let empty = AnimeWatchStatusSummary(
        totalCount: 0,
        watchingCount: 0,
        plannedCount: 0,
        completedCount: 0,
        statusCounts: AnimeWatchStatusFilter.allCases.map {
            AnimeWatchStatusCount(filter: $0, count: 0)
        }
    )
}

// MARK: - AnimeWatchStatusPresentation

struct AnimeWatchStatusPresentation {
    let summary: AnimeWatchStatusSummary
    let filteredItems: [MyListCollectionItem]
}
