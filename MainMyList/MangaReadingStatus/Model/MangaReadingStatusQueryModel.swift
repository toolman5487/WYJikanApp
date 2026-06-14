//
//  MangaReadingStatusQueryModel.swift
//  WYJikanApp
//

import Foundation

// MARK: - MangaReadingStatusFilter

enum MangaReadingStatusFilter: Hashable, Identifiable, Sendable {
    case all
    case status(MangaReadingStatus)

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
            return "books.vertical"
        case .status(let status):
            return status.systemImageName
        }
    }

    static let allCases: [MangaReadingStatusFilter] = [
        .all,
        .status(.planned),
        .status(.reading),
        .status(.onHold),
        .status(.completed),
        .status(.dropped)
    ]
}

// MARK: - MangaReadingStatusCount

struct MangaReadingStatusCount: Identifiable, Sendable {
    let filter: MangaReadingStatusFilter
    let count: Int

    var id: String { filter.id }
}

// MARK: - MangaReadingStatusSummary

struct MangaReadingStatusSummary: Sendable {
    let totalCount: Int
    let readingCount: Int
    let plannedCount: Int
    let completedCount: Int
    let statusCounts: [MangaReadingStatusCount]

    static let empty = MangaReadingStatusSummary(
        totalCount: 0,
        readingCount: 0,
        plannedCount: 0,
        completedCount: 0,
        statusCounts: MangaReadingStatusFilter.allCases.map {
            MangaReadingStatusCount(filter: $0, count: 0)
        }
    )
}

// MARK: - MangaReadingStatusPresentation

struct MangaReadingStatusPresentation {
    let summary: MangaReadingStatusSummary
    let filteredItems: [MyListCollectionItem]
}
