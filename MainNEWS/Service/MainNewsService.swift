//
//  MainNewsService.swift
//  WYJikanApp
//

import Foundation
import OSLog

nonisolated protocol MainNewsServicing: Sendable {
    func fetchLatestNews(
        from sources: [MainNewsSource],
        forceRefresh: Bool
    ) async throws -> MainNewsFeed
}

nonisolated extension MainNewsServicing {
    func fetchLatestNews(forceRefresh: Bool = false) async throws -> MainNewsFeed {
        try await fetchLatestNews(
            from: MainNewsSource.allCases,
            forceRefresh: forceRefresh
        )
    }
}

nonisolated enum MainNewsServiceError: LocalizedError, Sendable {
    case invalidFeedURL(source: MainNewsSource)
    case invalidResponse(source: MainNewsSource)
    case serverError(source: MainNewsSource, statusCode: Int)
    case emptyFeed
    case parsingFailed(source: MainNewsSource, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidFeedURL(let source):
            return "\(source.displayName) RSS URL 格式錯誤。"
        case .invalidResponse(let source):
            return "\(source.displayName) 回應格式異常。"
        case .serverError(let source, let statusCode):
            return "\(source.displayName) 暫時無法取得新聞（HTTP \(statusCode)）。"
        case .emptyFeed:
            return "目前沒有可顯示的動漫新聞。"
        case .parsingFailed(let source, let message):
            return "\(source.displayName) RSS 解析失敗：\(message)"
        }
    }
}

nonisolated final class MainNewsService: MainNewsServicing {
    private static let cacheTTL: TimeInterval = 900
    private static let maximumArticleCount = 80

    private let session: URLSession
    private let cache = MainNewsResponseCache()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchLatestNews(
        from sources: [MainNewsSource] = MainNewsSource.allCases,
        forceRefresh: Bool = false
    ) async throws -> MainNewsFeed {
        var articles: [MainNewsArticle] = []
        var errors: [Error] = []

        for source in sources {
            do {
                let sourceArticles = try await fetchArticles(
                    from: source,
                    forceRefresh: forceRefresh
                )
                articles.append(contentsOf: sourceArticles)
            } catch {
                errors.append(error)
                AppLogger.network.warning(
                    "news feed failed \(source.displayName, privacy: .public) \(error.localizedDescription, privacy: .public)"
                )
            }
        }

        let visibleArticles = Self.sortedArticles(
            from: Self.deduplicatedArticles(articles)
        )
        .prefix(Self.maximumArticleCount)

        guard !visibleArticles.isEmpty else {
            if let firstError = errors.first {
                throw firstError
            }
            throw MainNewsServiceError.emptyFeed
        }

        return MainNewsFeed(
            updatedAt: Date(),
            articles: Array(visibleArticles)
        )
    }

    private func fetchArticles(
        from source: MainNewsSource,
        forceRefresh: Bool
    ) async throws -> [MainNewsArticle] {
        if !forceRefresh,
           let cachedArticles = await cache.articles(for: source) {
            AppLogger.cache.debug("news cache hit \(source.displayName, privacy: .public)")
            return cachedArticles
        }

        let data = try await fetchFeedData(from: source)
        let articles = try MainNewsRSSParser(source: source).parse(data)
        await cache.insert(
            articles,
            for: source,
            ttl: Self.cacheTTL
        )
        return articles
    }

    private func fetchFeedData(from source: MainNewsSource) async throws -> Data {
        guard let url = URL(string: source.feedURLString) else {
            throw MainNewsServiceError.invalidFeedURL(source: source)
        }

        var request = URLRequest(url: url)
        request.setValue(
            "application/rss+xml, application/xml, text/xml, */*",
            forHTTPHeaderField: "Accept"
        )
        request.setValue(
            "WYJikanApp/1.0",
            forHTTPHeaderField: "User-Agent"
        )

        AppLogger.network.debug("GET \(url.absoluteString, privacy: .public)")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MainNewsServiceError.invalidResponse(source: source)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw MainNewsServiceError.serverError(
                source: source,
                statusCode: httpResponse.statusCode
            )
        }

        return data
    }

    private static func deduplicatedArticles(_ articles: [MainNewsArticle]) -> [MainNewsArticle] {
        var seenIDs = Set<String>()
        var uniqueArticles: [MainNewsArticle] = []

        for article in articles {
            let normalizedID = article.linkURL.absoluteString.lowercased()
            guard seenIDs.insert(normalizedID).inserted else { continue }
            uniqueArticles.append(article)
        }

        return uniqueArticles
    }

    private static func sortedArticles(from articles: [MainNewsArticle]) -> [MainNewsArticle] {
        articles.sorted { lhs, rhs in
            switch (lhs.publishedAt, rhs.publishedAt) {
            case let (lhsDate?, rhsDate?):
                return lhsDate > rhsDate
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
            }
        }
    }
}

private actor MainNewsResponseCache {
    private struct Entry: Sendable {
        let articles: [MainNewsArticle]
        let expirationDate: Date
    }

    private var storage: [MainNewsSource: Entry] = [:]

    func articles(for source: MainNewsSource, now: Date = Date()) -> [MainNewsArticle]? {
        switch storage[source] {
        case .some(let entry) where entry.expirationDate > now:
            return entry.articles
        case .some:
            storage.removeValue(forKey: source)
            return nil
        case .none:
            return nil
        }
    }

    func insert(
        _ articles: [MainNewsArticle],
        for source: MainNewsSource,
        ttl: TimeInterval,
        now: Date = Date()
    ) {
        storage[source] = Entry(
            articles: articles,
            expirationDate: now.addingTimeInterval(ttl)
        )
    }
}

private nonisolated final class MainNewsRSSParser: NSObject, XMLParserDelegate {
    private let source: MainNewsSource
    private var items: [MainNewsRSSItem] = []
    private var currentItem: MainNewsRSSItem?
    private var currentElementName: String?
    private var textBuffer = ""

    init(source: MainNewsSource) {
        self.source = source
    }

    func parse(_ data: Data) throws -> [MainNewsArticle] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.shouldProcessNamespaces = false
        parser.shouldReportNamespacePrefixes = true

        guard parser.parse() else {
            let message = parser.parserError?.localizedDescription ?? "Unknown XML parser error"
            throw MainNewsServiceError.parsingFailed(
                source: source,
                message: message
            )
        }

        return items.compactMap { $0.article(source: source) }
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        let name = normalizedElementName(
            elementName: elementName,
            qualifiedName: qName
        )

        switch name {
        case "item", "entry":
            currentItem = MainNewsRSSItem()
            currentElementName = nil
            textBuffer = ""
        case "enclosure":
            guard let imageURL = Self.url(
                from: attributeDict["url"],
                requiresImageLikeURL: true
            ) else { return }
            updateCurrentItem { item in
                if item.imageURL == nil {
                    item.imageURL = imageURL
                }
            }
        case "media:content", "media:thumbnail":
            guard let imageURL = Self.url(
                from: attributeDict["url"],
                requiresImageLikeURL: false
            ) else { return }
            updateCurrentItem { item in
                if item.imageURL == nil {
                    item.imageURL = imageURL
                }
            }
        case "link":
            if let linkURL = Self.url(
                from: attributeDict["href"],
                requiresImageLikeURL: false
            ) {
                updateCurrentItem { item in
                    if item.linkURL == nil {
                        item.linkURL = linkURL
                    }
                }
            }
            guard currentItem != nil else { return }
            currentElementName = name
            textBuffer = ""
        default:
            guard currentItem != nil else { return }
            currentElementName = name
            textBuffer = ""
        }
    }

    func parser(
        _ parser: XMLParser,
        foundCharacters string: String
    ) {
        guard currentItem != nil,
              currentElementName != nil else { return }
        textBuffer += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let name = normalizedElementName(
            elementName: elementName,
            qualifiedName: qName
        )

        switch name {
        case "item", "entry":
            if let currentItem {
                items.append(currentItem)
            }
            self.currentItem = nil
            currentElementName = nil
            textBuffer = ""
        default:
            guard currentItem != nil,
                  currentElementName == name else { return }
            assignCurrentText(to: name)
            currentElementName = nil
            textBuffer = ""
        }
    }

    private func assignCurrentText(to elementName: String) {
        let text = textBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        switch elementName {
        case "title":
            updateCurrentItem { item in
                if item.title == nil {
                    item.title = text
                }
            }
        case "link":
            guard let linkURL = Self.url(
                from: text,
                requiresImageLikeURL: false
            ) else { return }
            updateCurrentItem { item in
                if item.linkURL == nil {
                    item.linkURL = linkURL
                }
            }
        case "description", "summary", "content", "content:encoded":
            let summary = Self.plainText(fromHTML: text)
            updateCurrentItem { item in
                if item.summary == nil {
                    item.summary = summary
                }
            }
        case "pubdate", "published", "updated":
            guard let publishedAt = MainNewsDateParser.date(from: text) else { return }
            updateCurrentItem { item in
                if item.publishedAt == nil {
                    item.publishedAt = publishedAt
                }
            }
        case "author", "dc:creator":
            let author = Self.plainText(fromHTML: text)
            updateCurrentItem { item in
                if item.author == nil {
                    item.author = author
                }
            }
        case "category":
            updateCurrentItem { item in
                item.categories.append(text)
            }
        default:
            break
        }
    }

    private func updateCurrentItem(_ update: (inout MainNewsRSSItem) -> Void) {
        guard var item = currentItem else { return }
        update(&item)
        currentItem = item
    }

    private func normalizedElementName(
        elementName: String,
        qualifiedName: String?
    ) -> String {
        switch qualifiedName?.isEmpty == false {
        case true:
            return qualifiedName?.lowercased() ?? elementName.lowercased()
        case false:
            return elementName.lowercased()
        }
    }

    private static func url(
        from value: String?,
        requiresImageLikeURL: Bool
    ) -> URL? {
        guard let value else { return nil }
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else { return nil }

        let urlString: String
        switch trimmedValue.hasPrefix("//") {
        case true:
            urlString = "https:\(trimmedValue)"
        case false:
            urlString = trimmedValue
        }

        guard let url = URL(string: urlString) else { return nil }
        guard requiresImageLikeURL else { return url }

        let lowercasedPath = url.path.lowercased()
        let imageExtensions = [".jpg", ".jpeg", ".png", ".webp", ".gif"]
        return imageExtensions.contains(where: lowercasedPath.hasSuffix) ? url : nil
    }

    private static func plainText(fromHTML html: String) -> String {
        let withoutTags = html.replacingOccurrences(
            of: "<[^>]+>",
            with: " ",
            options: .regularExpression
        )
        return withoutTags
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private nonisolated struct MainNewsRSSItem: Sendable {
    var title: String?
    var summary: String?
    var linkURL: URL?
    var imageURL: URL?
    var publishedAt: Date?
    var author: String?
    var categories: [String] = []

    func article(source: MainNewsSource) -> MainNewsArticle? {
        guard let title = title?.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty,
              let linkURL else {
            return nil
        }

        return MainNewsArticle(
            id: linkURL.absoluteString,
            source: source,
            title: title,
            summary: normalizedOptionalText(summary),
            linkURL: linkURL,
            imageURL: imageURL,
            publishedAt: publishedAt,
            author: normalizedOptionalText(author),
            categories: categories.filter { !$0.isEmpty }
        )
    }

    private func normalizedOptionalText(_ value: String?) -> String? {
        let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmedValue,
              !trimmedValue.isEmpty else {
            return nil
        }
        return trimmedValue
    }
}

private nonisolated enum MainNewsDateParser {
    static func date(from value: String) -> Date? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else { return nil }

        if let isoDate = isoDate(from: trimmedValue) {
            return isoDate
        }

        for format in dateFormats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = format

            if let date = formatter.date(from: trimmedValue) {
                return date
            }
        }

        return nil
    }

    private static var dateFormats: [String] {
        [
            "EEE, d MMM yyyy HH:mm:ss Z",
            "EEE, dd MMM yyyy HH:mm:ss Z",
            "EEE, d MMM yyyy HH:mm Z",
            "EEE, dd MMM yyyy HH:mm Z",
            "yyyy-MM-dd HH:mm:ss Z"
        ]
    }

    private static func isoDate(from value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        if let date = formatter.date(from: value) {
            return date
        }

        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}
