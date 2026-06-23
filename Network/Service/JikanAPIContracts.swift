//
//  JikanAPIContracts.swift
//  WYJikanApp
//
//

import Foundation

// MARK: - JikanAPIError

nonisolated enum JikanAPIError: LocalizedError, AppUserFacingError {
    case invalidURL
    case noData
    case decodingError(Error)
    case networkError(Error)
    case rateLimited(retryAfter: TimeInterval)
    case serverError(statusCode: Int)

    nonisolated var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL is invalid and the request could not be created."
        case .noData:
            return "The server returned no data."
        case .decodingError(let error):
            return "Failed to decode JSON: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .rateLimited(let retryAfter):
            return "Rate limited. Retry after \(Int(ceil(retryAfter))) seconds."
        case .serverError(let statusCode):
            return "Server error (HTTP \(statusCode))."
        }
    }

    nonisolated var userMessage: String {
        switch self {
        case .invalidURL:
            return "資料來源設定暫時異常，請稍後再試。"
        case .noData:
            return "目前沒有可顯示的資料。"
        case .decodingError:
            return "資料格式暫時無法讀取，請稍後再試。"
        case .networkError(let error):
            return error.userFacingMessage
        case .rateLimited(let retryAfter):
            let seconds = max(1, Int(ceil(retryAfter)))
            return "請求太頻繁，請約 \(seconds) 秒後再試。"
        case .serverError(let statusCode):
            switch statusCode {
            case 500...599:
                return "伺服器暫時無法回應，請稍後再試。"
            default:
                return "目前無法載入資料，請稍後再試。"
            }
        }
    }
}

// MARK: - JikanAPIRequestTarget

nonisolated enum JikanAPIRequestTarget: Sendable {
    case path(String)
    case absoluteURL(String)
}

// MARK: - JikanAPICachePolicy

nonisolated enum JikanAPICachePolicy: Sendable {
    case remoteOnly
    case cacheFirst(ttl: TimeInterval)
    case reloadIgnoringCache(ttl: TimeInterval)
}

nonisolated enum JikanAPIRequestScope: Hashable, Sendable {
    case home
    case categoryList
    case news
    case myList
    case search
}

// MARK: - JikanCacheDuration

nonisolated enum JikanCacheDuration {
    static let search: TimeInterval = 45
    static let paging: TimeInterval = 120
    static let feed: TimeInterval = 300
    static let genreItems: TimeInterval = 300
    static let detail: TimeInterval = 600
    static let genreList: TimeInterval = 86_400
}

nonisolated extension JikanAPICachePolicy {
    static func resolved(forceRefresh: Bool, ttl: TimeInterval) -> JikanAPICachePolicy {
        forceRefresh ? .reloadIgnoringCache(ttl: ttl) : .cacheFirst(ttl: ttl)
    }

    static func search(forceRefresh: Bool = false) -> JikanAPICachePolicy {
        resolved(forceRefresh: forceRefresh, ttl: JikanCacheDuration.search)
    }

    static func paging(page: Int, forceRefresh: Bool = false) -> JikanAPICachePolicy {
        let ttl = page == 1 ? JikanCacheDuration.feed : JikanCacheDuration.paging
        return resolved(forceRefresh: forceRefresh, ttl: ttl)
    }

    static func feed(forceRefresh: Bool = false) -> JikanAPICachePolicy {
        resolved(forceRefresh: forceRefresh, ttl: JikanCacheDuration.feed)
    }

    static func detail(forceRefresh: Bool = false) -> JikanAPICachePolicy {
        resolved(forceRefresh: forceRefresh, ttl: JikanCacheDuration.detail)
    }

    static func genreList(forceRefresh: Bool = false) -> JikanAPICachePolicy {
        resolved(forceRefresh: forceRefresh, ttl: JikanCacheDuration.genreList)
    }
}

// MARK: - JikanAPIRequest

nonisolated struct JikanAPIRequest: Sendable {
    let target: JikanAPIRequestTarget
    let queryItems: [URLQueryItem]
    let method: String
    let cachePolicy: JikanAPICachePolicy
    let scope: JikanAPIRequestScope?

    init(
        path: String,
        queryItems: [URLQueryItem] = [],
        method: String = "GET",
        cachePolicy: JikanAPICachePolicy = .remoteOnly,
        scope: JikanAPIRequestScope? = nil
    ) {
        self.target = .path(path)
        self.queryItems = queryItems
        self.method = method
        self.cachePolicy = cachePolicy
        self.scope = scope
    }

    init(
        absoluteURL: String,
        queryItems: [URLQueryItem] = [],
        method: String = "GET",
        cachePolicy: JikanAPICachePolicy = .remoteOnly,
        scope: JikanAPIRequestScope? = nil
    ) {
        self.target = .absoluteURL(absoluteURL)
        self.queryItems = queryItems
        self.method = method
        self.cachePolicy = cachePolicy
        self.scope = scope
    }
}

// MARK: - JikanAPIServicing

nonisolated protocol JikanAPIServicing: Sendable {
    func send<T: Decodable & Sendable>(_ request: JikanAPIRequest) async throws -> T
    func fetch<T: Decodable & Sendable>(
        endpoint: String,
        cachePolicy: JikanAPICachePolicy,
        queryItems: [URLQueryItem]?
    ) async throws -> T
    func fetchFromURL<T: Decodable & Sendable>(
        _ urlString: String,
        cachePolicy: JikanAPICachePolicy
    ) async throws -> T
    func clearCache() async
}

// MARK: - JikanAPIServicing Convenience

nonisolated extension JikanAPIServicing {
    func fetch<T: Decodable & Sendable>(
        endpoint: String,
        cachePolicy: JikanAPICachePolicy,
        queryItems: [URLQueryItem]? = nil,
        scope: JikanAPIRequestScope
    ) async throws -> T {
        try await send(
            JikanAPIRequest(
                path: endpoint,
                queryItems: queryItems ?? [],
                cachePolicy: cachePolicy,
                scope: scope
            )
        )
    }

    func fetch<T: Decodable & Sendable>(
        endpoint: String,
        scope: JikanAPIRequestScope
    ) async throws -> T {
        try await fetch(
            endpoint: endpoint,
            cachePolicy: .remoteOnly,
            scope: scope
        )
    }

    func fetch<T: Decodable & Sendable>(
        endpoint: String,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        try await fetch(
            endpoint: endpoint,
            cachePolicy: .remoteOnly,
            queryItems: queryItems
        )
    }

    func fetch<T: Decodable & Sendable>(endpoint: String) async throws -> T {
        try await fetch(
            endpoint: endpoint,
            cachePolicy: .remoteOnly,
            queryItems: nil
        )
    }

    func fetch<T: Decodable & Sendable>(
        endpoint: String,
        cachePolicy: JikanAPICachePolicy
    ) async throws -> T {
        try await fetch(
            endpoint: endpoint,
            cachePolicy: cachePolicy,
            queryItems: nil
        )
    }

    func fetchFromURL<T: Decodable & Sendable>(_ urlString: String) async throws -> T {
        try await fetchFromURL(urlString, cachePolicy: .remoteOnly)
    }
}
