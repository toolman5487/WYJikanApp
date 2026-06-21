//
//  JikanAPIRequestState.swift
//  WYJikanApp
//
//

import Foundation

// MARK: - JikanAPIResponseCache

actor JikanAPIResponseCache {
    private struct Entry: Sendable {
        let data: Data
        let expirationDate: Date
        let staleFallbackExpirationDate: Date
    }

    private var storage: [String: Entry] = [:]
    private var nextCleanupDate = Date.distantPast

    func data(for key: String, now: Date = Date()) -> Data? {
        guard let entry = storage[key] else { return nil }

        if entry.expirationDate > now {
            return entry.data
        }

        removeIfStaleFallbackExpired(for: key, entry: entry, now: now)
        return nil
    }

    func staleData(for key: String, now: Date = Date()) -> Data? {
        guard let entry = storage[key] else { return nil }

        guard entry.staleFallbackExpirationDate > now else {
            storage.removeValue(forKey: key)
            return nil
        }

        return entry.data
    }

    func insert(
        _ data: Data,
        for key: String,
        ttl: TimeInterval,
        staleFallbackRetention: TimeInterval,
        cleanupInterval: TimeInterval,
        now: Date = Date()
    ) {
        removeExpiredStaleFallbacksIfNeeded(now: now, cleanupInterval: cleanupInterval)

        storage[key] = Entry(
            data: data,
            expirationDate: now.addingTimeInterval(ttl),
            staleFallbackExpirationDate: now.addingTimeInterval(ttl + staleFallbackRetention)
        )
    }

    func removeAll() {
        storage.removeAll()
        nextCleanupDate = .distantPast
    }

    private func removeIfStaleFallbackExpired(for key: String, entry: Entry, now: Date) {
        guard entry.staleFallbackExpirationDate <= now else { return }
        storage.removeValue(forKey: key)
    }

    private func removeExpiredStaleFallbacksIfNeeded(
        now: Date,
        cleanupInterval: TimeInterval
    ) {
        guard now >= nextCleanupDate else { return }

        storage = storage.filter { _, entry in
            entry.staleFallbackExpirationDate > now
        }
        nextCleanupDate = now.addingTimeInterval(cleanupInterval)
    }
}

// MARK: - JikanAPIInFlightRequestStore

actor JikanAPIInFlightRequestStore {
    private struct Entry {
        let id: UUID
        let task: Task<Data, Error>
        let priority: TaskPriority
    }

    private var entries: [String: Entry] = [:]

    func task(
        for key: String,
        priority: TaskPriority,
        create: @escaping @Sendable () -> Task<Data, Error>
    ) -> (id: UUID, task: Task<Data, Error>, isNew: Bool) {
        if let existingEntry = entries[key],
           existingEntry.priority >= priority {
            return (existingEntry.id, existingEntry.task, false)
        }

        let entry = Entry(
            id: UUID(),
            task: create(),
            priority: priority
        )
        entries[key] = entry
        return (entry.id, entry.task, true)
    }

    func removeTask(for key: String, id: UUID) {
        guard entries[key]?.id == id else { return }
        entries.removeValue(forKey: key)
    }
}

// MARK: - JikanAPIRequestGovernor

actor JikanAPIRequestGovernor {
    private let tokenCapacity: Double
    private let tokenRefillInterval: TimeInterval
    private let minimumRequestInterval: TimeInterval

    private var availableTokens: Double
    private var lastTokenRefillDate: Date
    private var nextRequestDate = Date.distantPast
    private var rateLimitExpirationDate = Date.distantPast

    init(
        maximumRequestsPerSecond: Int = 3,
        maximumRequestsPerMinute: Int = 60,
        now: Date = Date()
    ) {
        let burstSize = max(1, maximumRequestsPerSecond)
        let refillableRequestsPerMinute = max(1, maximumRequestsPerMinute - burstSize)

        self.tokenCapacity = Double(burstSize)
        self.tokenRefillInterval = 60 / Double(refillableRequestsPerMinute)
        self.minimumRequestInterval = (1 / Double(burstSize)) + 0.02
        self.availableTokens = Double(burstSize)
        self.lastTokenRefillDate = now
    }

    func waitForPermit() async throws {
        while true {
            try Task.checkCancellation()

            let now = Date()
            if rateLimitExpirationDate > now {
                throw JikanAPIError.rateLimited(
                    retryAfter: rateLimitExpirationDate.timeIntervalSince(now)
                )
            }

            refillTokens(at: now)

            if nextRequestDate > now {
                try await sleep(for: nextRequestDate.timeIntervalSince(now))
                continue
            }

            guard availableTokens >= 1 else {
                let missingTokens = 1 - availableTokens
                try await sleep(for: missingTokens * tokenRefillInterval)
                continue
            }

            availableTokens -= 1
            nextRequestDate = now.addingTimeInterval(minimumRequestInterval)
            return
        }
    }

    func recordRateLimit(retryAfter: TimeInterval, now: Date = Date()) {
        let expirationDate = now.addingTimeInterval(max(retryAfter, minimumRequestInterval))
        guard expirationDate > rateLimitExpirationDate else { return }

        rateLimitExpirationDate = expirationDate
        availableTokens = min(1, tokenCapacity)
        lastTokenRefillDate = expirationDate
        nextRequestDate = max(nextRequestDate, expirationDate)
    }

    private func refillTokens(at now: Date) {
        guard now > lastTokenRefillDate else { return }

        let elapsedTime = now.timeIntervalSince(lastTokenRefillDate)
        availableTokens = min(
            tokenCapacity,
            availableTokens + (elapsedTime / tokenRefillInterval)
        )
        lastTokenRefillDate = now
    }

    private func sleep(for interval: TimeInterval) async throws {
        guard interval > 0 else { return }

        let nanoseconds = UInt64((interval * 1_000_000_000).rounded(.up))
        try await Task.sleep(nanoseconds: nanoseconds)
    }
}

// MARK: - JikanAPITransientFailureBackoffStore

actor JikanAPITransientFailureBackoffStore {
    private struct Entry: Sendable {
        let statusCode: Int
        let expirationDate: Date
    }

    private var storage: [String: Entry] = [:]
    private var nextCleanupDate = Date.distantPast

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

    func record(
        statusCode: Int,
        for key: String,
        cooldown: TimeInterval,
        cleanupInterval: TimeInterval,
        now: Date = Date()
    ) {
        removeExpiredEntriesIfNeeded(now: now, cleanupInterval: cleanupInterval)

        storage[key] = Entry(
            statusCode: statusCode,
            expirationDate: now.addingTimeInterval(cooldown)
        )
    }

    func remove(for key: String) {
        storage.removeValue(forKey: key)
    }

    func removeAll() {
        storage.removeAll()
        nextCleanupDate = .distantPast
    }

    private func removeExpiredEntriesIfNeeded(
        now: Date,
        cleanupInterval: TimeInterval
    ) {
        guard now >= nextCleanupDate else { return }

        storage = storage.filter { _, entry in
            entry.expirationDate > now
        }
        nextCleanupDate = now.addingTimeInterval(cleanupInterval)
    }
}
