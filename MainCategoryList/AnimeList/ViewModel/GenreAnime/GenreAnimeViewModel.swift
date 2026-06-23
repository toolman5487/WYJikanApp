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
        case error(FeatureLoadFailure)
    }

    enum ScreenState {
        case loading
        case error(FeatureLoadFailure)
        case empty
        case content(sections: [AnimeGenreSection], inlineError: FeatureLoadFailure?)
    }

    // MARK: - Constants

    private static let genreErrorMessage = "目前無法載入分類資料，請稍後再試"

    // MARK: - Published State

    @Published private(set) var genreSections: [AnimeGenreSection] = []
    @Published private(set) var loadState: LoadState = .idle
    @Published private(set) var canLoadMore: Bool = false

    // MARK: - Derived State

    var canPullLoadMore: Bool {
        guard canLoadMore, !isLoadingMore else { return false }
        if case .error = loadState { return false }
        return true
    }

    var screenState: ScreenState {
        switch loadState {
        case .loadingInitial where genreSections.isEmpty:
            return .loading
        case .error(let failure) where !hasDisplayableSections:
            return .error(failure)
        case .idle:
            if genreSections.isEmpty {
                return .empty
            }

            return .content(
                sections: sectionsForDisplay,
                inlineError: inlineErrorMessage
            )
        case .loadingInitial:
            if genreSections.isEmpty {
                return .empty
            }

            return .content(
                sections: sectionsForDisplay,
                inlineError: inlineErrorMessage
            )
        case .loadingMore:
            if genreSections.isEmpty {
                return .empty
            }

            return .content(
                sections: sectionsForDisplay,
                inlineError: inlineErrorMessage
            )
        case .paused:
            if genreSections.isEmpty {
                return .empty
            }

            return .content(
                sections: sectionsForDisplay,
                inlineError: inlineErrorMessage
            )
        case .loaded:
            if genreSections.isEmpty {
                return .empty
            }

            return .content(
                sections: sectionsForDisplay,
                inlineError: inlineErrorMessage
            )
        case .error:
            if genreSections.isEmpty {
                return .empty
            }

            return .content(
                sections: sectionsForDisplay,
                inlineError: inlineErrorMessage
            )
        }
    }

    // MARK: - Dependencies

    private let service: MainCategoryListServicing
    private var batchLoader: MainCategoryGenreBatchLoader<AnimeListGenreDTO, AnimeListRandomDTO>
    private var itemRequestLimit: Int

    // MARK: - Loading State

    private var loadTask: Task<Void, Never>?
    private var allLocalizedGenres: [AnimeListGenreDTO] = []

    // MARK: - Lifecycle

    init(
        service: MainCategoryListServicing,
        batchConfiguration: MainCategoryGenreBatchConfiguration = .standard
    ) {
        self.service = service
        self.itemRequestLimit = batchConfiguration.itemRequestLimit
        self.batchLoader = MainCategoryGenreBatchLoader(configuration: batchConfiguration)
    }

    // MARK: - Public Methods

    func configureBatchIfNeeded(_ configuration: MainCategoryGenreBatchConfiguration) {
        guard canReplaceBatchConfiguration else { return }
        itemRequestLimit = configuration.itemRequestLimit
        batchLoader = MainCategoryGenreBatchLoader(configuration: configuration)
    }

    func loadIfNeeded() {
        switch loadState {
        case .idle where genreSections.isEmpty:
            loadSections()
        case .paused:
            resumeLoading()
        case .idle:
            break
        case .loadingInitial:
            break
        case .loadingMore:
            break
        case .loaded:
            break
        case .error:
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
        case .loadingInitial:
            return
        case .loadingMore:
            return
        case .idle:
            break
        case .paused:
            break
        case .loaded:
            break
        case .error:
            break
        }
        guard canLoadMore else { return }
        runLoadTask { await $0.startGenreBatch(.loadMore) }
    }

    func retryLoading() {
        guard batchLoader.hasPendingBatch else {
            loadSections()
            return
        }

        runLoadTask { await $0.continuePendingGenreBatch() }
    }

    func stop() {
        loadTask?.cancel()
        loadTask = nil

        switch loadState {
        case .loadingInitial:
            loadState = .paused
        case .loadingMore:
            loadState = .paused
        case .idle:
            break
        case .paused:
            break
        case .loaded:
            break
        case .error:
            break
        }
    }
}

// MARK: - Screen State

private extension GenreAnimeViewModel {
    var hasDisplayableSections: Bool {
        genreSections.contains { !$0.items.isEmpty }
    }

    var sectionsForDisplay: [AnimeGenreSection] {
        switch loadState {
        case .error:
            return genreSections.filter { !$0.items.isEmpty }
        case .idle:
            return genreSections
        case .loadingInitial:
            return genreSections
        case .loadingMore:
            return genreSections
        case .paused:
            return genreSections
        case .loaded:
            return genreSections
        }
    }

    var canReplaceBatchConfiguration: Bool {
        switch loadState {
        case .idle where genreSections.isEmpty:
            return true
        case .idle:
            return false
        case .loadingInitial:
            return false
        case .loadingMore:
            return false
        case .paused:
            return false
        case .loaded:
            return false
        case .error:
            return false
        }
    }

    var inlineErrorMessage: FeatureLoadFailure? {
        guard case .error(let failure) = loadState else { return nil }
        return failure
    }

}

extension GenreAnimeViewModel {
    var isLoadingMore: Bool {
        loadState == .loadingMore
    }

    var skeletonItemCount: Int {
        itemRequestLimit
    }
}

// MARK: - Task Management

private extension GenreAnimeViewModel {
    func runLoadTask(
        _ operation: @escaping @MainActor (GenreAnimeViewModel) async -> Void
    ) {
        loadTask?.cancel()
        loadTask = Task(priority: .utility) { [weak self] in
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
            loadState = .error(FeatureLoadFailure(message: Self.genreErrorMessage))
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
                return try await self.fetchGenreItems(genreId: genre.id)
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
                return try await self.fetchGenreItems(genreId: genre.id)
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
            loadState = genreSections.isEmpty ? .error(FeatureLoadFailure(message: Self.genreErrorMessage)) : .loaded
        case .failed(let failure):
            loadState = .error(failure)
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
    func fetchGenreItems(genreId: Int) async throws -> [AnimeListRandomDTO] {
        let response = try await service.fetchAnimeByGenre(
            genreId: genreId,
            limit: itemRequestLimit
        )
        return response.data
    }
}
