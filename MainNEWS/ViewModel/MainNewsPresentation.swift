//
//  MainNewsPresentation.swift
//  WYJikanApp
//

import Foundation

nonisolated enum MainNewsScreenState: Sendable {
    case loading
    case content(MainNewsContent)
    case refreshing(MainNewsContent)
    case empty
    case error(message: String)
}

nonisolated enum MainNewsSourceFilter: Hashable, Identifiable, Sendable {
    case all
    case source(MainNewsSource)

    nonisolated var id: String {
        switch self {
        case .all:
            return "all"
        case .source(let source):
            return source.id
        }
    }

    nonisolated var title: String {
        switch self {
        case .all:
            return "全部"
        case .source(let source):
            return source.displayName
        }
    }

    nonisolated var systemImageName: String {
        switch self {
        case .all:
            return "newspaper"
        case .source:
            return "dot.radiowaves.left.and.right"
        }
    }

    nonisolated static var allFilters: [MainNewsSourceFilter] {
        [.all] + MainNewsSource.allCases.map(MainNewsSourceFilter.source)
    }
}

nonisolated struct MainNewsHeaderContent: Hashable, Sendable {
    let title: String
    let subtitle: String
    let countText: String?
    let updatedText: String?
}

nonisolated struct MainNewsContent: Hashable, Sendable {
    let rows: [MainNewsRow]
    let countText: String
    let updatedText: String?
}

nonisolated struct MainNewsRow: Identifiable, Hashable, Sendable {
    let id: String
    let sourceName: String
    let title: String
    let summary: String?
    let linkURL: URL
    let imageURL: URL?
    let publishedText: String?
    let authorText: String?
    let categoryText: String?
}

nonisolated struct MainNewsPresentationBuilder: Sendable {
    private let maximumSummaryLength: Int

    init(maximumSummaryLength: Int = 180) {
        self.maximumSummaryLength = maximumSummaryLength
    }

    var filterItems: [MainNewsSourceFilter] {
        MainNewsSourceFilter.allFilters
    }

    func makeHeaderContent(for screenState: MainNewsScreenState) -> MainNewsHeaderContent {
        switch screenState {
        case .content(let content), .refreshing(let content):
            return headerContent(
                countText: content.countText,
                updatedText: content.updatedText
            )
        case .loading, .empty, .error:
            return headerContent(
                countText: nil,
                updatedText: nil
            )
        }
    }

    func makeContent(
        articles: [MainNewsArticle],
        selectedFilter: MainNewsSourceFilter,
        updatedAt: Date?
    ) -> MainNewsContent? {
        let rows = filteredArticles(
            from: articles,
            selectedFilter: selectedFilter
        )
        .map(row(from:))

        guard !rows.isEmpty else { return nil }

        return MainNewsContent(
            rows: rows,
            countText: "\(rows.count) 則",
            updatedText: updatedAt.map { "更新於 \(Self.relativeDateText(from: $0))" }
        )
    }

    private func headerContent(
        countText: String?,
        updatedText: String?
    ) -> MainNewsHeaderContent {
        MainNewsHeaderContent(
            title: "動漫新知",
            subtitle: "整理動畫、漫畫與串流平台相關新聞。",
            countText: countText,
            updatedText: updatedText
        )
    }

    private func filteredArticles(
        from articles: [MainNewsArticle],
        selectedFilter: MainNewsSourceFilter
    ) -> [MainNewsArticle] {
        switch selectedFilter {
        case .all:
            return articles
        case .source(let source):
            return articles.filter { $0.source == source }
        }
    }

    private func row(from article: MainNewsArticle) -> MainNewsRow {
        MainNewsRow(
            id: article.id,
            sourceName: article.source.displayName,
            title: article.title,
            summary: summaryText(from: article.summary),
            linkURL: article.linkURL,
            imageURL: article.imageURL,
            publishedText: article.publishedAt.map(Self.relativeDateText(from:)),
            authorText: article.author,
            categoryText: categoryText(from: article.categories)
        )
    }

    private func summaryText(from summary: String?) -> String? {
        guard let summary = summary?.trimmingCharacters(in: .whitespacesAndNewlines),
              !summary.isEmpty else {
            return nil
        }

        guard summary.count > maximumSummaryLength else { return summary }
        return "\(summary.prefix(maximumSummaryLength))..."
    }

    private func categoryText(from categories: [String]) -> String? {
        let visibleCategories = categories
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(2)

        guard !visibleCategories.isEmpty else { return nil }
        return visibleCategories.joined(separator: " / ")
    }

    private static func relativeDateText(from date: Date) -> String {
        let oneWeek: TimeInterval = 60 * 60 * 24 * 7
        guard abs(date.timeIntervalSinceNow) < oneWeek else {
            return date.formatted(date: .abbreviated, time: .shortened)
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
