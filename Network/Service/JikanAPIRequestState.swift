//
//  JikanAPIRequestState.swift
//  WYJikanApp
//
//

import Foundation

// MARK: - JikanAPIResponseCache

actor JikanAPIResponseCache {

    // MARK: - Types

    private struct Entry: Sendable {
        let data: Data
        let expirationDate: Date
        let staleFallbackExpirationDate: Date
    }

    // MARK: - Properties

    private var storage: [String: Entry] = [:]
    private var nextCleanupDate = Date.distantPast

    // MARK: - Public Methods

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

    // MARK: - Private Methods

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

    // MARK: - Types

    struct Lease: Sendable {
        let requestID: UUID
        let waiterID: UUID
        let task: Task<Data, Error>
        let isNewRequest: Bool
    }

    private struct Entry {
        let id: UUID
        let task: Task<Data, Error>
        var waiterIDs: Set<UUID>
    }

    // MARK: - Properties

    private var entries: [String: Entry] = [:]

    // MARK: - Public Methods

    func acquireTask(
        for key: String,
        create: @escaping @Sendable () -> Task<Data, Error>
    ) -> Lease {
        let waiterID = UUID()

        if var existingEntry = entries[key] {
            existingEntry.waiterIDs.insert(waiterID)
            entries[key] = existingEntry
            return Lease(
                requestID: existingEntry.id,
                waiterID: waiterID,
                task: existingEntry.task,
                isNewRequest: false
            )
        }

        let entry = Entry(
            id: UUID(),
            task: create(),
            waiterIDs: [waiterID]
        )
        entries[key] = entry
        return Lease(
            requestID: entry.id,
            waiterID: waiterID,
            task: entry.task,
            isNewRequest: true
        )
    }

    func releaseWaiter(
        for key: String,
        requestID: UUID,
        waiterID: UUID,
        cancelTaskIfUnused: Bool
    ) {
        guard var entry = entries[key],
              entry.id == requestID,
              entry.waiterIDs.remove(waiterID) != nil else {
            return
        }

        guard entry.waiterIDs.isEmpty else {
            entries[key] = entry
            return
        }

        entries.removeValue(forKey: key)
        if cancelTaskIfUnused {
            entry.task.cancel()
        }
    }
}

// MARK: - JikanAPIRequestGovernor

actor JikanAPIRequestGovernor {

    // MARK: - Types

    private struct ConcurrencyWaiter {
        let continuation: CheckedContinuation<Void, Error>
    }

    // MARK: - Properties

    private let maximumConcurrentRequests: Int
    private let tokenCapacity: Double
    private let tokenRefillInterval: TimeInterval
    private let minimumRequestInterval: TimeInterval

    private var activeRequestCount = 0
    private var pendingConcurrencyOrder: [UUID] = []
    private var pendingConcurrencyWaiters: [UUID: ConcurrencyWaiter] = [:]
    private var knownConcurrencyWaiterIDs = Set<UUID>()
    private var cancelledConcurrencyWaiterIDs = Set<UUID>()
    private var availableTokens: Double
    private var lastTokenRefillDate: Date
    private var nextRequestDate = Date.distantPast
    private var rateLimitExpirationDate = Date.distantPast

    // MARK: - Lifecycle

    init(
        maximumConcurrentRequests: Int = 2,
        maximumRequestsPerSecond: Int = 3,
        maximumRequestsPerMinute: Int = 60,
        now: Date = Date()
    ) {
        self.maximumConcurrentRequests = max(1, maximumConcurrentRequests)
        let burstSize = max(1, maximumRequestsPerSecond)
        let refillableRequestsPerMinute = max(1, maximumRequestsPerMinute - burstSize)

        self.tokenCapacity = Double(burstSize)
        self.tokenRefillInterval = 60 / Double(refillableRequestsPerMinute)
        self.minimumRequestInterval = (1 / Double(burstSize)) + 0.02
        self.availableTokens = Double(burstSize)
        self.lastTokenRefillDate = now
    }

    // MARK: - Public Methods

    func acquirePermit() async throws {
        try await acquireConcurrencyPermit()

        do {
            try await waitForRatePermit()
        } catch {
            releasePermit()
            throw error
        }
    }

    func releasePermit() {
        while let waiterID = pendingConcurrencyOrder.first {
            pendingConcurrencyOrder.removeFirst()

            guard let waiter = pendingConcurrencyWaiters.removeValue(
                forKey: waiterID
            ) else {
                continue
            }

            waiter.continuation.resume()
            return
        }

        activeRequestCount = max(0, activeRequestCount - 1)
    }

    func recordRateLimit(retryAfter: TimeInterval, now: Date = Date()) {
        let expirationDate = now.addingTimeInterval(max(retryAfter, minimumRequestInterval))
        guard expirationDate > rateLimitExpirationDate else { return }

        rateLimitExpirationDate = expirationDate
        availableTokens = min(1, tokenCapacity)
        lastTokenRefillDate = expirationDate
        nextRequestDate = max(nextRequestDate, expirationDate)
    }

    // MARK: - Concurrency

    private func acquireConcurrencyPermit() async throws {
        let waiterID = UUID()
        knownConcurrencyWaiterIDs.insert(waiterID)
        defer {
            knownConcurrencyWaiterIDs.remove(waiterID)
            cancelledConcurrencyWaiterIDs.remove(waiterID)
        }

        guard activeRequestCount >= maximumConcurrentRequests else {
            activeRequestCount += 1
            return
        }

        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                registerConcurrencyWaiter(
                    waiterID: waiterID,
                    continuation: continuation
                )
            }
        } onCancel: {
            Task {
                await self.cancelConcurrencyWaiter(waiterID: waiterID)
            }
        }
    }

    private func registerConcurrencyWaiter(
        waiterID: UUID,
        continuation: CheckedContinuation<Void, Error>
    ) {
        if cancelledConcurrencyWaiterIDs.remove(waiterID) != nil {
            continuation.resume(throwing: CancellationError())
            return
        }

        guard activeRequestCount >= maximumConcurrentRequests else {
            activeRequestCount += 1
            continuation.resume()
            return
        }

        pendingConcurrencyOrder.append(waiterID)
        pendingConcurrencyWaiters[waiterID] = ConcurrencyWaiter(
            continuation: continuation
        )
    }

    private func cancelConcurrencyWaiter(waiterID: UUID) {
        guard let waiter = pendingConcurrencyWaiters.removeValue(
            forKey: waiterID
        ) else {
            if knownConcurrencyWaiterIDs.contains(waiterID) {
                cancelledConcurrencyWaiterIDs.insert(waiterID)
            }
            return
        }

        pendingConcurrencyOrder.removeAll { $0 == waiterID }
        waiter.continuation.resume(throwing: CancellationError())
    }

    // MARK: - Rate Limit

    private func waitForRatePermit() async throws {
        while true {
            try Task.checkCancellation()

            let now = Date()
            if rateLimitExpirationDate > now {
                try await sleep(
                    for: rateLimitExpirationDate.timeIntervalSince(now)
                )
                continue
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

    // MARK: - Types

    private struct Entry: Sendable {
        let statusCode: Int
        let expirationDate: Date
    }

    // MARK: - Properties

    private var storage: [String: Entry] = [:]
    private var nextCleanupDate = Date.distantPast

    // MARK: - Public Methods

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

    // MARK: - Private Methods

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
