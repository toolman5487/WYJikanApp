//
//  JikanAPIService.swift
//  WYJikanApp
//
//

import Foundation
import OSLog

// MARK: - JikanAPIResponseState

private enum JikanAPIResponseState: Sendable {
    case success
    case emptyBody
    case serverError(statusCode: Int)
}

// MARK: - JikanAPIExecutionControl

private enum JikanAPIExecutionControl: Error, Sendable {
    case retryServerError(statusCode: Int, dataCount: Int)
}

// MARK: - JikanAPIService

nonisolated final class JikanAPIService: Sendable {

    // MARK: - Constants

    private static let defaultRateLimitCooldown: TimeInterval = 60
    private static let serverFailureCooldown: TimeInterval = 60
    private static let staleResponseFallbackRetention: TimeInterval = 3_600
    private static let storeCleanupInterval: TimeInterval = 300
    private static let transientRetryDelays: [UInt64] = [
        400_000_000,
        900_000_000
    ]

    // MARK: - Properties

    private var baseURL: String { APIConfig.jikanBaseURL }
    private let session: URLSession
    private let decoder: JSONDecoder
    private let responseCache = JikanAPIResponseCache()
    private let inFlightRequestStore = JikanAPIInFlightRequestStore()
    private let requestLifecycleExecutor: any RequestLifecycleExecuting
    private let requestGovernor = JikanAPIRequestGovernor()
    private let transientFailureBackoffStore = JikanAPITransientFailureBackoffStore()

    // MARK: - Lifecycle

    init(
        requestLifecycleExecutor: any RequestLifecycleExecuting,
        session: URLSession = .shared,
        decoder: JSONDecoder = JikanAPIService.makeDefaultDecoder()
    ) {
        self.requestLifecycleExecutor = requestLifecycleExecutor
        self.session = session
        self.decoder = decoder
    }

    // MARK: - Cache Management

    func clearCache() async {
        await responseCache.removeAll()
        await transientFailureBackoffStore.removeAll()
        session.configuration.urlCache?.removeAllCachedResponses()
    }

    // MARK: - Public API

    func send<T: Decodable & Sendable>(_ request: JikanAPIRequest) async throws -> T {
        let urlRequest = try makeURLRequest(for: request)
        let data = try await data(
            for: urlRequest,
            cachePolicy: request.cachePolicy,
            scope: request.scope
        )

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            let urlString = urlRequest.url?.absoluteString ?? "invalid-url"
            AppLogger.decoding.error(
                "decode failed \(urlString, privacy: .public) \(error.localizedDescription, privacy: .public)"
            )
            throw JikanAPIError.decodingError(error)
        }
    }
}

// MARK: - JikanAPIServicing Conformance

nonisolated extension JikanAPIService: JikanAPIServicing {}

// MARK: - JikanAPIService Decoder

private extension JikanAPIService {

    nonisolated static func makeDefaultDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

// MARK: - JikanAPIService URL Building

private extension JikanAPIService {

    nonisolated func makeURL(for request: JikanAPIRequest) throws -> URL {
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

    nonisolated func makeURLRequest(for request: JikanAPIRequest) throws -> URLRequest {
        let url = try makeURL(for: request)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        return urlRequest
    }

    nonisolated func cacheKey(for urlRequest: URLRequest) -> String {
        let method = urlRequest.httpMethod ?? "GET"
        let urlString = urlRequest.url?.absoluteString ?? "invalid-url"
        return "\(method) \(urlString)"
    }
}

// MARK: - JikanAPIService Response Handling

private extension JikanAPIService {

    nonisolated func responseState(for response: URLResponse, data: Data) -> JikanAPIResponseState {
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
}

// MARK: - JikanAPIService Retry Policy

private extension JikanAPIService {

    nonisolated func isRetriableServerStatusCode(_ statusCode: Int) -> Bool {
        (500...599).contains(statusCode)
    }

    nonisolated func retryDelayNanoseconds(for attempt: Int) -> UInt64? {
        guard attempt < Self.transientRetryDelays.count else { return nil }
        return Self.transientRetryDelays[attempt]
    }

    nonisolated func retryAfterInterval(
        from response: URLResponse,
        now: Date = Date()
    ) -> TimeInterval? {
        guard let httpResponse = response as? HTTPURLResponse,
              let headerValue = httpResponse.value(forHTTPHeaderField: "Retry-After")?
                .trimmingCharacters(in: .whitespacesAndNewlines),
              !headerValue.isEmpty else {
            return nil
        }

        if let seconds = TimeInterval(headerValue) {
            return max(0, seconds)
        }

        let dateFormats = [
            "EEE',' dd MMM yyyy HH':'mm':'ss zzz",
            "EEEE',' dd-MMM-yy HH':'mm':'ss zzz",
            "EEE MMM d HH':'mm':'ss yyyy"
        ]

        for dateFormat in dateFormats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = dateFormat

            if let retryDate = formatter.date(from: headerValue) {
                return max(0, retryDate.timeIntervalSince(now))
            }
        }

        return nil
    }
}

// MARK: - JikanAPIService Remote Execution

private extension JikanAPIService {

    nonisolated func execute(
        _ urlRequest: URLRequest,
        scope: RequestLifecycleScope
    ) async throws -> Data {
        guard let url = urlRequest.url else {
            throw JikanAPIError.invalidURL
        }

        var attempt = 0

        while true {
            do {
                return try await performRequest(
                    urlRequest,
                    scope: scope,
                    attempt: attempt
                )
            } catch JikanAPIExecutionControl.retryServerError(
                let statusCode,
                let dataCount
            ) {
                guard let delay = retryDelayNanoseconds(for: attempt) else {
                    throw JikanAPIError.serverError(statusCode: statusCode)
                }

                attempt += 1
                AppLogger.network.warning(
                    "transient server error HTTP \(statusCode) bytes \(dataCount) retry \(attempt) \(url.absoluteString, privacy: .public)"
                )
                try await Task.sleep(nanoseconds: delay)
                continue
            } catch let apiError as JikanAPIError {
                throw apiError
            } catch is CancellationError {
                throw CancellationError()
            } catch let urlError as URLError where urlError.code == .cancelled {
                throw CancellationError()
            } catch {
                AppLogger.network.error(
                    "request failed \(url.absoluteString, privacy: .public) \(error.localizedDescription, privacy: .public)"
                )
                throw JikanAPIError.networkError(error)
            }
        }
    }

    nonisolated func performRequest(
        _ urlRequest: URLRequest,
        scope: RequestLifecycleScope,
        attempt: Int
    ) async throws -> Data {
        try await requestLifecycleExecutor.perform(
            scope: scope,
            inactivePolicy: .pauseQueued
        ) { [self] in
            try await performGovernedRequest(
                urlRequest,
                attempt: attempt
            )
        }
    }

    nonisolated func performGovernedRequest(
        _ urlRequest: URLRequest,
        attempt: Int
    ) async throws -> Data {
        try await requestGovernor.acquirePermit()
        let urlString = urlRequest.url?.absoluteString ?? "invalid-url"
        AppLogger.network.debug(
            "\(urlRequest.httpMethod ?? "GET") \(urlString, privacy: .public)"
        )

        do {
            let (data, response) = try await session.data(for: urlRequest)

            switch responseState(for: response, data: data) {
            case .success:
                if let httpResponse = response as? HTTPURLResponse {
                    AppLogger.network.debug(
                        "HTTP \(httpResponse.statusCode) bytes \(data.count) \(urlString, privacy: .public)"
                    )
                }
                await requestGovernor.releasePermit()
                return data

            case .emptyBody:
                AppLogger.network.error("empty body \(urlString, privacy: .public)")
                throw JikanAPIError.noData

            case .serverError(let statusCode):
                if statusCode == 429 {
                    let retryAfter = max(
                        retryAfterInterval(from: response) ?? Self.defaultRateLimitCooldown,
                        1
                    )
                    await requestGovernor.recordRateLimit(retryAfter: retryAfter)
                    AppLogger.network.warning(
                        "rate limited HTTP 429 retry after \(retryAfter, format: .fixed(precision: 1)) seconds \(urlString, privacy: .public)"
                    )
                    throw JikanAPIError.rateLimited(retryAfter: retryAfter)
                }

                if isRetriableServerStatusCode(statusCode),
                   retryDelayNanoseconds(for: attempt) != nil {
                    throw JikanAPIExecutionControl.retryServerError(
                        statusCode: statusCode,
                        dataCount: data.count
                    )
                }

                AppLogger.network.error(
                    "server error HTTP \(statusCode) bytes \(data.count) \(urlString, privacy: .public)"
                )
                throw JikanAPIError.serverError(statusCode: statusCode)
            }
        } catch {
            await requestGovernor.releasePermit()
            throw error
        }
    }
}

// MARK: - JikanAPIService Data Loading

private extension JikanAPIService {

    nonisolated func data(
        for urlRequest: URLRequest,
        cachePolicy: JikanAPICachePolicy,
        scope: RequestLifecycleScope
    ) async throws -> Data {
        let key = cacheKey(for: urlRequest)

        switch cachePolicy {
        case .remoteOnly:
            try await throwIfTransientFailureBackoffIsActive(for: key)
            return try await sharedDataTask(for: urlRequest, key: key, scope: scope)

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
            return try await loadRemoteCachingResponse(
                for: urlRequest,
                key: key,
                ttl: ttl,
                scope: scope
            )

        case .reloadIgnoringCache(let ttl):
            try await throwIfTransientFailureBackoffIsActive(for: key)
            AppLogger.cache.debug("cache reload \(key, privacy: .public)")
            return try await loadRemoteCachingResponse(
                for: urlRequest,
                key: key,
                ttl: ttl,
                scope: scope
            )
        }
    }

    nonisolated func throwIfTransientFailureBackoffIsActive(for key: String) async throws {
        guard let statusCode = await transientFailureBackoffStore.statusCode(for: key) else {
            return
        }

        AppLogger.cache.debug("transient failure backoff \(key, privacy: .public)")
        throw JikanAPIError.serverError(statusCode: statusCode)
    }

    nonisolated func loadRemoteCachingResponse(
        for urlRequest: URLRequest,
        key: String,
        ttl: TimeInterval,
        scope: RequestLifecycleScope
    ) async throws -> Data {
        do {
            let freshData = try await sharedDataTask(
                for: urlRequest,
                key: key,
                scope: scope
            )
            await responseCache.insert(
                freshData,
                for: key,
                ttl: ttl,
                staleFallbackRetention: Self.staleResponseFallbackRetention,
                cleanupInterval: Self.storeCleanupInterval
            )
            await transientFailureBackoffStore.remove(for: key)
            return freshData
        } catch JikanAPIError.rateLimited(let retryAfter) {
            if let staleData = await responseCache.staleData(for: key) {
                AppLogger.cache.debug("cache stale fallback HTTP 429 \(key, privacy: .public)")
                return staleData
            }
            throw JikanAPIError.rateLimited(retryAfter: retryAfter)
        } catch JikanAPIError.serverError(let statusCode) where isRetriableServerStatusCode(statusCode) {
            if let staleData = await responseCache.staleData(for: key) {
                AppLogger.cache.debug("cache stale fallback HTTP \(statusCode) \(key, privacy: .public)")
                return staleData
            }
            throw JikanAPIError.serverError(statusCode: statusCode)
        } catch {
            throw error
        }
    }
}

// MARK: - JikanAPIService In-Flight Requests

private extension JikanAPIService {

    nonisolated func sharedDataTask(
        for urlRequest: URLRequest,
        key: String,
        scope: RequestLifecycleScope
    ) async throws -> Data {
        let priority = Task.currentPriority
        let lease = await inFlightRequestStore.acquireTask(for: key) {
            Task(priority: priority) {
                try await self.execute(urlRequest, scope: scope)
            }
        }

        if lease.isNewRequest {
            AppLogger.performance.debug("in-flight create \(key, privacy: .public)")
        } else {
            AppLogger.performance.debug("in-flight join \(key, privacy: .public)")
        }

        return try await withTaskCancellationHandler {
            do {
                let data = try await lease.task.value
                try Task.checkCancellation()
                await releaseInFlightWaiter(for: key, lease: lease)
                return data
            } catch JikanAPIError.serverError(let statusCode) where isRetriableServerStatusCode(statusCode) {
                await transientFailureBackoffStore.record(
                    statusCode: statusCode,
                    for: key,
                    cooldown: Self.serverFailureCooldown,
                    cleanupInterval: Self.storeCleanupInterval
                )
                await releaseInFlightWaiter(for: key, lease: lease)
                throw JikanAPIError.serverError(statusCode: statusCode)
            } catch {
                await releaseInFlightWaiter(for: key, lease: lease)
                throw error
            }
        } onCancel: {
            Task(priority: .utility) {
                await self.inFlightRequestStore.releaseWaiter(
                    for: key,
                    requestID: lease.requestID,
                    waiterID: lease.waiterID,
                    cancelTaskIfUnused: true
                )
            }
        }
    }

    nonisolated func releaseInFlightWaiter(
        for key: String,
        lease: JikanAPIInFlightRequestStore.Lease
    ) async {
        await inFlightRequestStore.releaseWaiter(
            for: key,
            requestID: lease.requestID,
            waiterID: lease.waiterID,
            cancelTaskIfUnused: false
        )
    }
}
