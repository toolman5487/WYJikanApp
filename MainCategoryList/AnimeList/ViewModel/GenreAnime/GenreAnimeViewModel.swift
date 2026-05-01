//
//  GenreAnimeViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/9.
//

import Foundation
import Combine

@MainActor
final class GenreAnimeViewModel: ObservableObject {

    // MARK: - Types

    enum LoadState: Equatable {
        case idle
        case loadingInitial
        case loadingMore
        case paused
        case loaded
        case error(message: String)
    }

    enum LoadMoreState: Equatable {
        case hidden
        case available
        case loading
    }

    enum ScreenState {
        case loading
        case error(String)
        case empty
        case content(sections: [AnimeGenreSection], inlineError: String?, loadMoreState: LoadMoreState)
    }

    private enum BatchPhase {
        case initial
        case loadMore

        var loadState: LoadState {
            switch self {
            case .initial:
                return .loadingInitial
            case .loadMore:
                return .loadingMore
            }
        }

        var batchSize: Int {
            switch self {
            case .initial:
                return GenreAnimeViewModel.initialGenreSections
            case .loadMore:
                return GenreAnimeViewModel.loadMoreGenreSections
            }
        }
    }

    private struct PendingBatch {
        let phase: BatchPhase
        let startIndex: Int
        let endIndex: Int
        var nextGenreIndex: Int
        var shouldApplyInitialDelay: Bool
    }

    // MARK: - Constants

    private static let initialGenreSections = 5
    private static let loadMoreGenreSections = 5
    private static let genreAnimeLimit = 5
    private static let maxRetryCount = 2
    private static let initialItemRequestDelay: Duration = .milliseconds(1200)
    private static let requestInterval: Duration = .seconds(1)
    private static let retryBackoff: Duration = .milliseconds(800)
    private static let genreErrorMessage = "目前無法載入分類資料，請稍後再試"

    // MARK: - Published State

    @Published private(set) var genreSections: [AnimeGenreSection] = []
    @Published private(set) var loadState: LoadState = .idle
    @Published private(set) var canLoadMore: Bool = false

    // MARK: - Derived State

    var screenState: ScreenState {
        switch loadState {
        case .loadingInitial where genreSections.isEmpty:
            return .loading
        case .error(let message) where genreSections.isEmpty:
            return .error(message)
        case .idle, .loadingInitial, .loadingMore, .paused, .loaded, .error:
            if genreSections.isEmpty {
                return .empty
            }

            return .content(
                sections: genreSections,
                inlineError: inlineErrorMessage,
                loadMoreState: footerLoadMoreState
            )
        }
    }

    // MARK: - Dependencies

    private let service: MainCategoryListServicing

    // MARK: - Loading State

    private var loadTask: Task<Void, Never>?
    private var allLocalizedGenres: [AnimeListGenreDTO] = []
    private var loadedGenreCount: Int = 0
    private var pendingBatch: PendingBatch?

    // MARK: - Lifecycle

    init(service: MainCategoryListServicing = MainCategoryListService()) {
        self.service = service
    }

    // MARK: - Public Methods

    func loadIfNeeded() {
        switch loadState {
        case .idle where genreSections.isEmpty:
            loadSections()
        case .paused:
            resumeLoading()
        case .idle, .loadingInitial, .loadingMore, .loaded, .error:
            break
        }
    }

    func loadSections() {
        loadTask?.cancel()
        resetLoadingContext()
        runLoadTask { await $0.fetchSections() }
    }

    func loadMoreSections() {
        switch loadState {
        case .loadingInitial, .loadingMore:
            return
        default:
            break
        }
        guard canLoadMore else { return }
        runLoadTask { await $0.startBatch(.loadMore) }
    }

    func stop() {
        loadTask?.cancel()
        loadTask = nil

        switch loadState {
        case .loadingInitial, .loadingMore:
            loadState = .paused
        case .idle, .paused, .loaded, .error:
            break
        }
    }

    // MARK: - Screen State Helpers

    private var inlineErrorMessage: String? {
        guard case .error(let message) = loadState else { return nil }
        return message
    }

    private var footerLoadMoreState: LoadMoreState {
        if !canLoadMore {
            return .hidden
        }

        return loadState == .loadingMore ? .loading : .available
    }

    // MARK: - Task Management

    private func runLoadTask(
        _ operation: @escaping @MainActor (GenreAnimeViewModel) async -> Void
    ) {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }
            await operation(self)
        }
    }

    // MARK: - Loading Lifecycle

    private func resetLoadingContext() {
        canLoadMore = false
        genreSections = []
        allLocalizedGenres = []
        loadedGenreCount = 0
        pendingBatch = nil
        loadState = .idle
    }

    private func resumeLoading() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }

            if self.pendingBatch != nil {
                await self.continuePendingBatch()
            } else if self.genreSections.isEmpty {
                if self.allLocalizedGenres.isEmpty {
                    await self.fetchSections()
                } else {
                    await self.startBatch(.initial)
                }
            } else {
                self.loadState = .loaded
            }
        }
    }

    private func fetchSections() async {
        loadState = .loadingInitial
        canLoadMore = false
        genreSections = []
        allLocalizedGenres = []
        loadedGenreCount = 0
        pendingBatch = nil
        
        do {
            let genres = try await service.fetchAnimeGenres().data
            let validGenres = genres.filter { genre in
                guard let name = genre.name else { return false }
                return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            allLocalizedGenres = validGenres.map(localizedGenre)
            guard !allLocalizedGenres.isEmpty else {
                loadState = .loaded
                return
            }

            await startBatch(.initial)
        } catch {
            guard !Task.isCancelled else { return }
            loadState = .error(message: Self.genreErrorMessage)
            canLoadMore = false
        }
    }

    // MARK: - Batch Loading

    private func startBatch(_ phase: BatchPhase) async {
        guard let batch = makePendingBatch(for: phase) else {
            canLoadMore = false
            loadState = genreSections.isEmpty ? .error(message: Self.genreErrorMessage) : .loaded
            return
        }

        pendingBatch = batch
        applyPlaceholdersIfNeeded(for: batch)
        await continuePendingBatch()
    }

    private func continuePendingBatch() async {
        guard var batch = pendingBatch else { return }

        loadState = batch.phase.loadState

        if batch.shouldApplyInitialDelay {
            try? await Task.sleep(for: Self.initialItemRequestDelay)
            guard !Task.isCancelled else {
                pendingBatch = batch
                return
            }
            batch.shouldApplyInitialDelay = false
            pendingBatch = batch
        }

        while batch.nextGenreIndex < batch.endIndex {
            let genre = allLocalizedGenres[batch.nextGenreIndex]
            let items = await fetchGenreItemsWithRetry(genreId: genre.id)
            guard !Task.isCancelled else {
                pendingBatch = batch
                return
            }

            updateGenreSection(genreId: genre.id, items: items)
            batch.nextGenreIndex += 1
            pendingBatch = batch

            if batch.nextGenreIndex < batch.endIndex {
                try? await Task.sleep(for: Self.requestInterval)
                guard !Task.isCancelled else {
                    pendingBatch = batch
                    return
                }
            }
        }

        loadedGenreCount = batch.endIndex
        pendingBatch = nil
        canLoadMore = loadedGenreCount < allLocalizedGenres.count
        loadState = .loaded
    }

    private func makePendingBatch(for phase: BatchPhase) -> PendingBatch? {
        let startIndex = loadedGenreCount
        let endIndex = min(startIndex + phase.batchSize, allLocalizedGenres.count)
        guard startIndex < endIndex else { return nil }

        return PendingBatch(
            phase: phase,
            startIndex: startIndex,
            endIndex: endIndex,
            nextGenreIndex: startIndex,
            shouldApplyInitialDelay: true
        )
    }

    private func applyPlaceholdersIfNeeded(for batch: PendingBatch) {
        let batchGenres = Array(allLocalizedGenres[batch.startIndex..<batch.endIndex])
        let placeholderSections = batchGenres.map { genre in
            AnimeGenreSection(genre: genre, items: [])
        }

        switch batch.phase {
        case .initial:
            if genreSections.isEmpty {
                genreSections = placeholderSections
            }
        case .loadMore:
            let missingSections = placeholderSections.filter { section in
                !genreSections.contains(where: { $0.genre.id == section.genre.id })
            }
            genreSections.append(contentsOf: missingSections)
        }
    }

    // MARK: - Section Updates

    private func updateGenreSection(genreId: Int, items: [AnimeListRandomDTO]) {
        guard let index = genreSections.firstIndex(where: { $0.genre.id == genreId }) else { return }
        genreSections[index] = AnimeGenreSection(
            genre: genreSections[index].genre,
            items: items
        )
    }

    // MARK: - Genre Mapping

    private func localizedGenre(_ genre: AnimeListGenreDTO) -> AnimeListGenreDTO {
        guard let englishName = genre.name else { return genre }
        let localizedName = AnimeGenreLocalizationModel.localizedName(for: englishName)
        return AnimeListGenreDTO(malId: genre.malId, name: localizedName)
    }

    // MARK: - Item Fetching

    private func fetchGenreItemsWithRetry(genreId: Int) async -> [AnimeListRandomDTO] {
        var attempt = 0
        while attempt <= Self.maxRetryCount {
            guard !Task.isCancelled else { return [] }
            do {
                let response = try await service.fetchAnimeByGenre(
                    genreId: genreId,
                    limit: Self.genreAnimeLimit
                )
                return response.data
            } catch {
                attempt += 1
                guard attempt <= Self.maxRetryCount else { return [] }
                try? await Task.sleep(for: Self.retryBackoff * attempt)
            }
        }
        return []
    }
}
