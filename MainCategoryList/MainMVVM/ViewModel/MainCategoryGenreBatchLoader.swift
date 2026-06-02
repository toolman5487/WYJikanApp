//
//  MainCategoryGenreBatchLoader.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/2.
//

import Foundation

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

struct MainCategoryGenreBatchConfiguration: Sendable {
    let initialBatchSize: Int
    let loadMoreBatchSize: Int
    let initialItemRequestDelay: Duration
    let requestInterval: Duration
}

enum MainCategoryGenreBatchResult: Equatable, Sendable {
    case empty
    case cancelled
    case finished(canLoadMore: Bool)
}

@MainActor
final class MainCategoryGenreBatchLoader<Genre: Identifiable, Item> where Genre.ID == Int {
    typealias BatchStartHandler = (MainCategoryGenreBatchPhase, [Genre]) -> Void
    typealias PhaseChangeHandler = (MainCategoryGenreBatchPhase) -> Void
    typealias ItemFetcher = (Genre) async -> [Item]
    typealias GenreItemsHandler = (Genre, [Item]) -> Void

    private struct PendingBatch {
        let phase: MainCategoryGenreBatchPhase
        let startIndex: Int
        let endIndex: Int
        var nextGenreIndex: Int
        var shouldApplyInitialDelay: Bool
    }

    private let configuration: MainCategoryGenreBatchConfiguration
    private var loadedGenreCount = 0
    private var pendingBatch: PendingBatch?

    var hasPendingBatch: Bool {
        pendingBatch != nil
    }

    init(configuration: MainCategoryGenreBatchConfiguration) {
        self.configuration = configuration
    }

    func reset() {
        loadedGenreCount = 0
        pendingBatch = nil
    }

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
            try? await Task.sleep(for: configuration.initialItemRequestDelay)
            guard !Task.isCancelled else {
                pendingBatch = batch
                return .cancelled
            }
            batch.shouldApplyInitialDelay = false
            pendingBatch = batch
        }

        while batch.nextGenreIndex < batch.endIndex {
            let genre = genres[batch.nextGenreIndex]
            let items = await fetchItems(genre)
            guard !Task.isCancelled else {
                pendingBatch = batch
                return .cancelled
            }

            didLoadGenreItems(genre, items)
            batch.nextGenreIndex += 1
            pendingBatch = batch

            if batch.nextGenreIndex < batch.endIndex {
                try? await Task.sleep(for: configuration.requestInterval)
                guard !Task.isCancelled else {
                    pendingBatch = batch
                    return .cancelled
                }
            }
        }

        loadedGenreCount = batch.endIndex
        pendingBatch = nil
        return .finished(canLoadMore: loadedGenreCount < genres.count)
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
}
