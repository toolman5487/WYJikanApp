//
//  JikanAPIService.swift
//  WYJikanApp
//
//

import Foundation
import OSLog

// MARK: - JikanAPIError

enum JikanAPIError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case networkError(Error)
    case serverError(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL is invalid and the request could not be created."
        case .noData:
            return "The server returned no data."
        case .decodingError(let error):
            return "Failed to decode JSON: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let statusCode):
            return "Server error (HTTP \(statusCode))."
        }
    }
}

// MARK: - JikanAPIRequestTarget

enum JikanAPIRequestTarget: Sendable {
    case path(String)
    case absoluteURL(String)
}

// MARK: - JikanAPICachePolicy

enum JikanAPICachePolicy: Sendable {
    case remoteOnly
    case cacheFirst(ttl: TimeInterval)
}

// MARK: - JikanAPIResponseState

enum JikanAPIResponseState: Sendable {
    case success
    case emptyBody
    case serverError(statusCode: Int)
}

// MARK: - JikanAPIRequest

struct JikanAPIRequest: Sendable {
    let target: JikanAPIRequestTarget
    let queryItems: [URLQueryItem]
    let method: String
    let cachePolicy: JikanAPICachePolicy

    init(
        path: String,
        queryItems: [URLQueryItem] = [],
        method: String = "GET",
        cachePolicy: JikanAPICachePolicy = .remoteOnly
    ) {
        self.target = .path(path)
        self.queryItems = queryItems
        self.method = method
        self.cachePolicy = cachePolicy
    }

    init(
        absoluteURL: String,
        queryItems: [URLQueryItem] = [],
        method: String = "GET",
        cachePolicy: JikanAPICachePolicy = .remoteOnly
    ) {
        self.target = .absoluteURL(absoluteURL)
        self.queryItems = queryItems
        self.method = method
        self.cachePolicy = cachePolicy
    }
}

// MARK: - JikanAPIServicing

protocol JikanAPIServicing {
    func send<T: Decodable>(_ request: JikanAPIRequest) async throws -> T
    func fetch<T: Decodable>(
        endpoint: String,
        cachePolicy: JikanAPICachePolicy,
        queryItems: [URLQueryItem]?
    ) async throws -> T
    func fetchFromURL<T: Decodable>(_ urlString: String, cachePolicy: JikanAPICachePolicy) async throws -> T
}

// MARK: - JikanAPIServicing Convenience

extension JikanAPIServicing {
    func fetch<T: Decodable>(
        endpoint: String,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        try await fetch(
            endpoint: endpoint,
            cachePolicy: .remoteOnly,
            queryItems: queryItems
        )
    }

    func fetch<T: Decodable>(endpoint: String) async throws -> T {
        try await fetch(
            endpoint: endpoint,
            cachePolicy: .remoteOnly,
            queryItems: nil
        )
    }

    func fetch<T: Decodable>(
        endpoint: String,
        cachePolicy: JikanAPICachePolicy
    ) async throws -> T {
        try await fetch(
            endpoint: endpoint,
            cachePolicy: cachePolicy,
            queryItems: nil
        )
    }

    func fetchFromURL<T: Decodable>(_ urlString: String) async throws -> T {
        try await fetchFromURL(urlString, cachePolicy: .remoteOnly)
    }
}

// MARK: - JikanAPIResponseCache

private actor JikanAPIResponseCache {
    private struct Entry: Sendable {
        let data: Data
        let expirationDate: Date
    }

    private var storage: [String: Entry] = [:]

    func data(for key: String, now: Date = Date()) -> Data? {
        switch storage[key] {
        case .some(let entry) where entry.expirationDate > now:
            return entry.data
        case .some:
            storage.removeValue(forKey: key)
            return nil
        case .none:
            return nil
        }
    }

    func insert(_ data: Data, for key: String, ttl: TimeInterval, now: Date = Date()) {
        storage[key] = Entry(
            data: data,
            expirationDate: now.addingTimeInterval(ttl)
        )
    }
}

// MARK: - JikanAPIInFlightRequestStore

private actor JikanAPIInFlightRequestStore {
    private var tasks: [String: Task<Data, Error>] = [:]

    func task(
        for key: String,
        create: @escaping @Sendable () -> Task<Data, Error>
    ) -> (task: Task<Data, Error>, isNew: Bool) {
        switch tasks[key] {
        case .some(let existingTask):
            return (existingTask, false)
        case .none:
            let task = create()
            tasks[key] = task
            return (task, true)
        }
    }

    func removeTask(for key: String) {
        tasks.removeValue(forKey: key)
    }
}

// MARK: - JikanAPITransientFailureBackoffStore

private actor JikanAPITransientFailureBackoffStore {
    private struct Entry: Sendable {
        let statusCode: Int
        let expirationDate: Date
    }

    private var storage: [String: Entry] = [:]

    func statusCode(for key: String, now: Date = Date()) -> Int? {
        switch storage[key] {
        case .some(let entry) where entry.expirationDate > now:
            return entry.statusCode
        case .some:
            storage.removeValue(forKey: key)
            return nil
        case .none:
            return nil
        }
    }

    func record(statusCode: Int, for key: String, cooldown: TimeInterval, now: Date = Date()) {
        storage[key] = Entry(
            statusCode: statusCode,
            expirationDate: now.addingTimeInterval(cooldown)
        )
    }

    func remove(for key: String) {
        storage.removeValue(forKey: key)
    }
}

// MARK: - JikanAPIService

final class JikanAPIService {
    
    static let shared = JikanAPIService()

    private static let transientFailureCooldown: TimeInterval = 60
    private static let transientRetryDelays: [UInt64] = [
        400_000_000,
        900_000_000
    ]
    
    private var baseURL: String { APIConfig.jikanBaseURL }
    private let session: URLSession
    private let decoder: JSONDecoder
    private let responseCache = JikanAPIResponseCache()
    private let inFlightRequestStore = JikanAPIInFlightRequestStore()
    private let transientFailureBackoffStore = JikanAPITransientFailureBackoffStore()
    
    init(
        session: URLSession = .shared,
        decoder: JSONDecoder = JikanAPIService.makeDefaultDecoder()
    ) {
        self.session = session
        self.decoder = decoder
    }
    
    // MARK: - Decoder

    private static func makeDefaultDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    // MARK: - URL Building

    private func makeURL(for request: JikanAPIRequest) throws -> URL {
        switch request.target {
        case .absoluteURL(let absoluteURL):
            guard var components = URLComponents(string: absoluteURL) else {
                throw JikanAPIError.invalidURL
            }
            if !request.queryItems.isEmpty {
                components.queryItems = request.queryItems
            }
            guard let url = components.url else {
                throw JikanAPIError.invalidURL
            }
            return url
        case .path(let path):
            guard var components = URLComponents(string: baseURL + path) else {
                throw JikanAPIError.invalidURL
            }

            if !request.queryItems.isEmpty {
                components.queryItems = request.queryItems
            }

            guard let url = components.url else {
                throw JikanAPIError.invalidURL
            }

            return url
        }
    }

    // MARK: - URL Request

    private func makeURLRequest(for request: JikanAPIRequest) throws -> URLRequest {
        let url = try makeURL(for: request)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        return urlRequest
    }

    // MARK: - Response Handling

    private func responseState(for response: URLResponse, data: Data) -> JikanAPIResponseState {
        guard let httpResponse = response as? HTTPURLResponse else {
            return data.isEmpty ? .emptyBody : .success
        }

        switch httpResponse.statusCode {
        case 200...299:
            return data.isEmpty ? .emptyBody : .success
        default:
            return .serverError(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - Cache Keys

    private func cacheKey(for urlRequest: URLRequest) -> String {
        let method = urlRequest.httpMethod ?? "GET"
        let urlString = urlRequest.url?.absoluteString ?? "invalid-url"
        return "\(method) \(urlString)"
    }

    // MARK: - Retry Policy

    private func isTransientStatusCode(_ statusCode: Int) -> Bool {
        statusCode == 429 || (500...599).contains(statusCode)
    }

    private func retryDelayNanoseconds(for attempt: Int) -> UInt64? {
        guard attempt < Self.transientRetryDelays.count else { return nil }
        return Self.transientRetryDelays[attempt]
    }

    // MARK: - Remote Execution

    private func execute(_ urlRequest: URLRequest) async throws -> Data {
        guard let url = urlRequest.url else {
            throw JikanAPIError.invalidURL
        }

        var attempt = 0

        while true {
            AppLogger.network.debug("\(urlRequest.httpMethod ?? "GET") \(url.absoluteString, privacy: .public)")

            do {
                let (data, response) = try await session.data(for: urlRequest)

                switch responseState(for: response, data: data) {
                case .success:
                    if let httpResponse = response as? HTTPURLResponse {
                        AppLogger.network.debug(
                            "HTTP \(httpResponse.statusCode) bytes \(data.count) \(url.absoluteString, privacy: .public)"
                        )
                    }
                    return data
                case .emptyBody:
                    AppLogger.network.error("empty body \(url.absoluteString, privacy: .public)")
                    throw JikanAPIError.noData
                case .serverError(let statusCode):
                    if isTransientStatusCode(statusCode),
                       let delay = retryDelayNanoseconds(for: attempt) {
                        attempt += 1
                        AppLogger.network.warning(
                            "transient server error HTTP \(statusCode) bytes \(data.count) retry \(attempt) \(url.absoluteString, privacy: .public)"
                        )
                        try await Task.sleep(nanoseconds: delay)
                        continue
                    }

                    AppLogger.network.error("server error HTTP \(statusCode) bytes \(data.count) \(url.absoluteString, privacy: .public)")
                    throw JikanAPIError.serverError(statusCode: statusCode)
                }
            } catch let apiError as JikanAPIError {
                throw apiError
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                AppLogger.network.error("request failed \(url.absoluteString, privacy: .public) \(error.localizedDescription, privacy: .public)")
                throw JikanAPIError.networkError(error)
            }
        }
    }

    // MARK: - Data Loading

    private func data(
        for urlRequest: URLRequest,
        cachePolicy: JikanAPICachePolicy
    ) async throws -> Data {
        let key = cacheKey(for: urlRequest)

        switch cachePolicy {
        case .remoteOnly:
            return try await sharedDataTask(for: urlRequest, key: key)
        case .cacheFirst(let ttl):
            if let cachedData = await responseCache.data(for: key) {
                AppLogger.cache.debug("cache hit \(key, privacy: .public)")
                return cachedData
            }

            if let statusCode = await transientFailureBackoffStore.statusCode(for: key) {
                AppLogger.cache.debug("cache transient failure backoff \(key, privacy: .public)")
                throw JikanAPIError.serverError(statusCode: statusCode)
            }

            AppLogger.cache.debug("cache miss \(key, privacy: .public)")
            do {
                let freshData = try await sharedDataTask(for: urlRequest, key: key)
                await responseCache.insert(freshData, for: key, ttl: ttl)
                await transientFailureBackoffStore.remove(for: key)
                return freshData
            } catch JikanAPIError.serverError(let statusCode) where isTransientStatusCode(statusCode) {
                await transientFailureBackoffStore.record(
                    statusCode: statusCode,
                    for: key,
                    cooldown: Self.transientFailureCooldown
                )
                throw JikanAPIError.serverError(statusCode: statusCode)
            } catch {
                throw error
            }
        }
    }

    // MARK: - In-Flight Requests

    private func sharedDataTask(for urlRequest: URLRequest, key: String) async throws -> Data {
        let taskState = await inFlightRequestStore.task(for: key) {
            Task {
                try await self.execute(urlRequest)
            }
        }

        if taskState.isNew {
            AppLogger.performance.debug("in-flight create \(key, privacy: .public)")
        } else {
            AppLogger.performance.debug("in-flight join \(key, privacy: .public)")
        }

        defer {
            if taskState.isNew {
                Task {
                    await self.inFlightRequestStore.removeTask(for: key)
                }
            }
        }

        return try await taskState.task.value
    }

    // MARK: - Public API

    func send<T: Decodable>(_ request: JikanAPIRequest) async throws -> T {
        let urlRequest = try makeURLRequest(for: request)
        let data = try await data(
            for: urlRequest,
            cachePolicy: request.cachePolicy
        )

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            let urlString = urlRequest.url?.absoluteString ?? "invalid-url"
            AppLogger.decoding.error("decode failed \(urlString, privacy: .public) \(error.localizedDescription, privacy: .public)")
            throw JikanAPIError.decodingError(error)
        }
    }

    func fetch<T: Decodable>(
        endpoint: String,
        cachePolicy: JikanAPICachePolicy,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        try await send(
            JikanAPIRequest(
                path: endpoint,
                queryItems: queryItems ?? [],
                cachePolicy: cachePolicy
            )
        )
    }

    func fetchFromURL<T: Decodable>(_ urlString: String, cachePolicy: JikanAPICachePolicy) async throws -> T {
        try await send(
            JikanAPIRequest(
                absoluteURL: urlString,
                cachePolicy: cachePolicy
            )
        )
    }
}

// MARK: - JikanAPIServicing Conformance

extension JikanAPIService: JikanAPIServicing {}
