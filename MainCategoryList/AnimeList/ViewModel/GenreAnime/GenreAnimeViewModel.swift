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

    // MARK: - Constants

    private static let genreAnimeLimit = 5
    private static let maxRetryCount = 2
    private static let retryBackoff: Duration = .milliseconds(800)
    private static let genreErrorMessage = "目前無法載入分類資料，請稍後再試"
    private static let batchConfiguration = MainCategoryGenreBatchConfiguration(
        initialBatchSize: 5,
        loadMoreBatchSize: 5,
        initialItemRequestDelay: .milliseconds(1200),
        requestInterval: .seconds(1)
    )

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
    private let batchLoader: MainCategoryGenreBatchLoader<AnimeListGenreDTO, AnimeListRandomDTO>

    // MARK: - Loading State

    private var loadTask: Task<Void, Never>?
    private var allLocalizedGenres: [AnimeListGenreDTO] = []

    // MARK: - Lifecycle

    init(service: MainCategoryListServicing = MainCategoryListService()) {
        self.service = service
        self.batchLoader = MainCategoryGenreBatchLoader(configuration: Self.batchConfiguration)
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
        case .idle, .paused, .loaded, .error:
            break
        }
        guard canLoadMore else { return }
        runLoadTask { await $0.startGenreBatch(.loadMore) }
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
}

// MARK: - Screen State

private extension GenreAnimeViewModel {
    var inlineErrorMessage: String? {
        guard case .error(let message) = loadState else { return nil }
        return message
    }

    var footerLoadMoreState: LoadMoreState {
        if !canLoadMore {
            return .hidden
        }

        return loadState == .loadingMore ? .loading : .available
    }
}

extension GenreAnimeViewModel {
    var isLoadingMore: Bool {
        loadState == .loadingMore
    }
}

// MARK: - Task Management

private extension GenreAnimeViewModel {
    func runLoadTask(
        _ operation: @escaping @MainActor (GenreAnimeViewModel) async -> Void
    ) {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }
            await operation(self)
        }
    }
}

// MARK: - Loading Lifecycle

private extension GenreAnimeViewModel {
    func resetLoadingContext() {
        canLoadMore = false
        genreSections = []
        allLocalizedGenres = []
        batchLoader.reset()
        loadState = .idle
    }

    func resumeLoading() {
        runLoadTask { viewModel in
            switch (
                viewModel.batchLoader.hasPendingBatch,
                viewModel.genreSections.isEmpty,
                viewModel.allLocalizedGenres.isEmpty
            ) {
            case (true, _, _):
                await viewModel.continuePendingGenreBatch()
            case (false, true, true):
                await viewModel.fetchSections()
            case (false, true, false):
                await viewModel.startGenreBatch(.initial)
            case (false, false, _):
                viewModel.loadState = .loaded
            }
        }
    }

    func fetchSections() async {
        loadState = .loadingInitial
        canLoadMore = false
        genreSections = []
        allLocalizedGenres = []
        batchLoader.reset()

        do {
            let genres = try await service.fetchAnimeGenres().data
            allLocalizedGenres = validLocalizedGenres(from: genres)
            guard !allLocalizedGenres.isEmpty else {
                loadState = .loaded
                return
            }

            await startGenreBatch(.initial)
        } catch {
            guard !Task.isCancelled else { return }
            loadState = .error(message: Self.genreErrorMessage)
            canLoadMore = false
        }
    }
}

// MARK: - Batch Loading

private extension GenreAnimeViewModel {
    func startGenreBatch(_ phase: MainCategoryGenreBatchPhase) async {
        let result = await batchLoader.startBatch(
            phase,
            genres: allLocalizedGenres,
            onBatchStart: applyPlaceholders,
            onPhaseChange: applyBatchPhase,
            fetchItems: { [weak self] genre in
                guard let self else { return [] }
                return await self.fetchGenreItemsWithRetry(genreId: genre.id)
            },
            didLoadGenreItems: { [weak self] genre, items in
                self?.updateGenreSection(genreId: genre.id, items: items)
            }
        )
        applyBatchResult(result)
    }

    func continuePendingGenreBatch() async {
        let result = await batchLoader.continuePendingBatch(
            genres: allLocalizedGenres,
            onPhaseChange: applyBatchPhase,
            fetchItems: { [weak self] genre in
                guard let self else { return [] }
                return await self.fetchGenreItemsWithRetry(genreId: genre.id)
            },
            didLoadGenreItems: { [weak self] genre, items in
                self?.updateGenreSection(genreId: genre.id, items: items)
            }
        )
        applyBatchResult(result)
    }

    func applyBatchPhase(_ phase: MainCategoryGenreBatchPhase) {
        switch phase {
        case .initial:
            loadState = .loadingInitial
        case .loadMore:
            loadState = .loadingMore
        }
    }

    func applyBatchResult(_ result: MainCategoryGenreBatchResult) {
        switch result {
        case .finished(let canLoadMore):
            self.canLoadMore = canLoadMore
            loadState = .loaded
        case .empty:
            canLoadMore = false
            loadState = genreSections.isEmpty ? .error(message: Self.genreErrorMessage) : .loaded
        case .cancelled:
            break
        }
    }

    func applyPlaceholders(
        phase: MainCategoryGenreBatchPhase,
        genres: [AnimeListGenreDTO]
    ) {
        let placeholderSections = genres.map { genre in
            AnimeGenreSection(genre: genre, items: [])
        }

        switch phase {
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
}

// MARK: - Section Updates

private extension GenreAnimeViewModel {
    func updateGenreSection(genreId: Int, items: [AnimeListRandomDTO]) {
        guard let index = genreSections.firstIndex(where: { $0.genre.id == genreId }) else { return }
        genreSections[index] = AnimeGenreSection(
            genre: genreSections[index].genre,
            items: items
        )
    }
}

// MARK: - Genre Mapping

private extension GenreAnimeViewModel {
    func validLocalizedGenres(from genres: [AnimeListGenreDTO]) -> [AnimeListGenreDTO] {
        genres
            .filter { genre in
                guard let name = genre.name else { return false }
                return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            .map(localizedGenre)
    }

    func localizedGenre(_ genre: AnimeListGenreDTO) -> AnimeListGenreDTO {
        guard let englishName = genre.name else { return genre }
        let localizedName = AnimeGenreLocalizationModel.localizedName(for: englishName)
        return AnimeListGenreDTO(malId: genre.malId, name: localizedName)
    }
}

// MARK: - Item Fetching

private extension GenreAnimeViewModel {
    func fetchGenreItemsWithRetry(genreId: Int) async -> [AnimeListRandomDTO] {
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
