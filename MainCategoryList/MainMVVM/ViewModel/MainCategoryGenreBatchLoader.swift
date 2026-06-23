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
    let initialItemRequestDelay: Duration
    let requestInterval: Duration

    static let standard = MainCategoryGenreBatchConfiguration(
        initialBatchSize: 3,
        loadMoreBatchSize: 5,
        itemRequestLimit: 5,
        initialItemRequestDelay: .milliseconds(1200),
        requestInterval: .seconds(1)
    )

    static func platformAdaptive(_ platform: UserInterfacePlatform) -> Self {
        MainCategoryGenreBatchConfiguration(
            initialBatchSize: platform.categoryGenreInitialBatchCount,
            loadMoreBatchSize: platform.categoryGenreLoadMoreBatchCount,
            itemRequestLimit: platform.categoryGenreItemRequestLimit,
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
    case finished(canLoadMore: Bool)
}

// MARK: - MainCategoryGenreBatchLoader

@MainActor
final class MainCategoryGenreBatchLoader<Genre: Identifiable, Item> where Genre.ID == Int {

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

        if batch.shouldApplyInitialDelay {
            guard await sleepUnlessCancelled(
                for: configuration.initialItemRequestDelay,
                batch: &batch
            ) else {
                return .cancelled
            }
            batch.shouldApplyInitialDelay = false
            pendingBatch = batch
        }

        while batch.nextGenreIndex < batch.endIndex {
            let genre = genres[batch.nextGenreIndex]
            let items: [Item]

            do {
                items = try await fetchItems(genre)
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

            didLoadGenreItems(genre, items)
            batch.nextGenreIndex += 1
            pendingBatch = batch

            if batch.nextGenreIndex < batch.endIndex {
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
        return .finished(canLoadMore: loadedGenreCount < genres.count)
    }

    // MARK: - Private Methods

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
