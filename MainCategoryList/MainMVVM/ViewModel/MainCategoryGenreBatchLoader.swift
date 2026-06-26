//
//  MainCategoryGenreBatchLoader.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/2.
//

import Foundation

// MARK: - MainCategoryGenreBatchPhase

enum MainCategoryGenreBatchPhase: Equatable, Sendable {
    case initial
    case loadMore

    func batchSize(using configuration: MainCategoryGenreBatchConfiguration) -> Int {
        switch self {
        case .initial:
            return configuration.initialBatchSize
        case .loadMore:
            return configuration.loadMoreBatchSize
        }
    }
}

// MARK: - MainCategoryGenreBatchConfiguration

struct MainCategoryGenreBatchConfiguration: Sendable {
    let initialBatchSize: Int
    let loadMoreBatchSize: Int
    let itemRequestLimit: Int
    let concurrentFetchCount: Int
    let initialItemRequestDelay: Duration
    let requestInterval: Duration

    static let phone = MainCategoryGenreBatchConfiguration(
        initialBatchSize: 3,
        loadMoreBatchSize: 5,
        itemRequestLimit: 5,
        concurrentFetchCount: 2,
        initialItemRequestDelay: .zero,
        requestInterval: .zero
    )

    static func platformAdaptive(_ platform: UserInterfacePlatform) -> Self {
        MainCategoryGenreBatchConfiguration(
            initialBatchSize: platform.categoryGenreInitialBatchCount,
            loadMoreBatchSize: platform.categoryGenreLoadMoreBatchCount,
            itemRequestLimit: platform.categoryGenreItemRequestLimit,
            concurrentFetchCount: platform.categoryGenreConcurrentFetchCount,
            initialItemRequestDelay: platform.categoryGenreInitialRequestDelay,
            requestInterval: platform.categoryGenreRequestInterval
        )
    }
}

// MARK: - MainCategoryGenreBatchResult

enum MainCategoryGenreBatchResult: Equatable, Sendable {
    case empty
    case cancelled
    case failed(FeatureLoadFailure)
    case finished(hasNextPage: Bool)
}

// MARK: - MainCategoryGenreBatchLoader

@MainActor
final class MainCategoryGenreBatchLoader<Genre: Identifiable & Sendable, Item: Sendable> where Genre.ID == Int {

    // MARK: - Types

    typealias BatchStartHandler = (MainCategoryGenreBatchPhase, [Genre]) -> Void
    typealias PhaseChangeHandler = (MainCategoryGenreBatchPhase) -> Void
    typealias ItemFetcher = (Genre) async throws -> [Item]
    typealias GenreItemsHandler = (Genre, [Item]) -> Void

    private struct PendingBatch {
        let phase: MainCategoryGenreBatchPhase
        let startIndex: Int
        let endIndex: Int
        var nextGenreIndex: Int
        var shouldApplyInitialDelay: Bool
    }

    // MARK: - Properties

    private let configuration: MainCategoryGenreBatchConfiguration
    private var loadedGenreCount = 0
    private var pendingBatch: PendingBatch?

    var hasPendingBatch: Bool {
        pendingBatch != nil
    }

    // MARK: - Lifecycle

    init(configuration: MainCategoryGenreBatchConfiguration) {
        self.configuration = configuration
    }

    func reset() {
        loadedGenreCount = 0
        pendingBatch = nil
    }

    // MARK: - Public Methods

    func startBatch(
        _ phase: MainCategoryGenreBatchPhase,
        genres: [Genre],
        onBatchStart: BatchStartHandler,
        onPhaseChange: PhaseChangeHandler,
        fetchItems: ItemFetcher,
        didLoadGenreItems: GenreItemsHandler
    ) async -> MainCategoryGenreBatchResult {
        guard let batch = makePendingBatch(for: phase, genres: genres) else {
            return .empty
        }

        pendingBatch = batch
        onBatchStart(phase, Array(genres[batch.startIndex..<batch.endIndex]))
        return await continuePendingBatch(
            genres: genres,
            onPhaseChange: onPhaseChange,
            fetchItems: fetchItems,
            didLoadGenreItems: didLoadGenreItems
        )
    }

    func continuePendingBatch(
        genres: [Genre],
        onPhaseChange: PhaseChangeHandler,
        fetchItems: ItemFetcher,
        didLoadGenreItems: GenreItemsHandler
    ) async -> MainCategoryGenreBatchResult {
        guard var batch = pendingBatch else { return .empty }

        onPhaseChange(batch.phase)

        if batch.shouldApplyInitialDelay,
           isPositiveDuration(configuration.initialItemRequestDelay) {
            guard await sleepUnlessCancelled(
                for: configuration.initialItemRequestDelay,
                batch: &batch
            ) else {
                return .cancelled
            }
            batch.shouldApplyInitialDelay = false
            pendingBatch = batch
        } else {
            batch.shouldApplyInitialDelay = false
            pendingBatch = batch
        }

        let concurrentFetchCount = max(1, configuration.concurrentFetchCount)

        while batch.nextGenreIndex < batch.endIndex {
            let chunkEnd = min(
                batch.nextGenreIndex + concurrentFetchCount,
                batch.endIndex
            )
            let chunk = Array(genres[batch.nextGenreIndex..<chunkEnd])

            do {
                try await fetchGenreChunk(
                    chunk,
                    fetchItems: fetchItems,
                    didLoadGenreItems: didLoadGenreItems
                )
            } catch is CancellationError {
                pendingBatch = batch
                return .cancelled
            } catch {
                guard !Task.isCancelled else {
                    pendingBatch = batch
                    return .cancelled
                }
                pendingBatch = batch
                return .failed(FeatureLoadFailure(error))
            }

            guard !Task.isCancelled else {
                pendingBatch = batch
                return .cancelled
            }

            batch.nextGenreIndex = chunkEnd
            pendingBatch = batch

            if (batch.nextGenreIndex < batch.endIndex),
               isPositiveDuration(configuration.requestInterval) {
                guard await sleepUnlessCancelled(
                    for: configuration.requestInterval,
                    batch: &batch
                ) else {
                    return .cancelled
                }
            }
        }

        loadedGenreCount = batch.endIndex
        pendingBatch = nil
        return .finished(hasNextPage: loadedGenreCount < genres.count)
    }

    // MARK: - Private Methods

    private func fetchGenreChunk(
        _ genres: [Genre],
        fetchItems: ItemFetcher,
        didLoadGenreItems: GenreItemsHandler
    ) async throws {
        for (index, genre) in genres.enumerated() {
            let items = try await fetchItems(genre)
            didLoadGenreItems(genre, items)

            guard index < genres.count - 1,
                  isPositiveDuration(configuration.requestInterval) else {
                continue
            }

            try? await Task.sleep(for: configuration.requestInterval)
            guard !Task.isCancelled else {
                throw CancellationError()
            }
        }
    }

    private func isPositiveDuration(_ duration: Duration) -> Bool {
        duration > Duration.zero
    }

    private func makePendingBatch(
        for phase: MainCategoryGenreBatchPhase,
        genres: [Genre]
    ) -> PendingBatch? {
        let startIndex = loadedGenreCount
        let endIndex = min(
            startIndex + phase.batchSize(using: configuration),
            genres.count
        )
        guard startIndex < endIndex else { return nil }

        return PendingBatch(
            phase: phase,
            startIndex: startIndex,
            endIndex: endIndex,
            nextGenreIndex: startIndex,
            shouldApplyInitialDelay: true
        )
    }

    private func sleepUnlessCancelled(
        for duration: Duration,
        batch: inout PendingBatch
    ) async -> Bool {
        try? await Task.sleep(for: duration)
        guard !Task.isCancelled else {
            pendingBatch = batch
            return false
        }
        return true
    }
}
