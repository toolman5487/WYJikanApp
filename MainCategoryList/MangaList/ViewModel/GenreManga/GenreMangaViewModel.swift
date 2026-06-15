//
//  GenreMangaViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/10.
//

import Foundation
import Combine

@MainActor
final class GenreMangaViewModel: ObservableObject {

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
        case content(sections: [MangaGenreSection], inlineError: FeatureLoadFailure?)
    }

    // MARK: - Constants

    private static let maxRetryCount = 2
    private static let retryBackoff: Duration = .milliseconds(800)
    private static let genreErrorMessage = "目前無法載入分類資料，請稍後再試"

    // MARK: - Published State

    @Published private(set) var genreSections: [MangaGenreSection] = []
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
        case .error(let failure) where genreSections.isEmpty:
            return .error(failure)
        case .idle, .loadingInitial, .loadingMore, .paused, .loaded, .error:
            if genreSections.isEmpty {
                return .empty
            }

            return .content(
                sections: genreSections,
                inlineError: inlineErrorMessage
            )
        }
    }

    // MARK: - Dependencies

    private let service: MainCategoryListServicing
    private var batchLoader: MainCategoryGenreBatchLoader<MangaListGenreDTO, MangaListRandomDTO>
    private var itemRequestLimit: Int

    // MARK: - Loading State

    private var loadTask: Task<Void, Never>?
    private var allLocalizedGenres: [MangaListGenreDTO] = []

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
        case .idle, .loadingInitial, .loadingMore, .loaded, .error:
            break
        }
    }

    func loadSections() {
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

private extension GenreMangaViewModel {
    var canReplaceBatchConfiguration: Bool {
        switch loadState {
        case .idle where genreSections.isEmpty:
            return true
        case .idle, .loadingInitial, .loadingMore, .paused, .loaded, .error:
            return false
        }
    }

    var inlineErrorMessage: FeatureLoadFailure? {
        guard case .error(let failure) = loadState else { return nil }
        return failure
    }

}

extension GenreMangaViewModel {
    var isLoadingMore: Bool {
        loadState == .loadingMore
    }

    var skeletonItemCount: Int {
        itemRequestLimit
    }
}

// MARK: - Task Management

private extension GenreMangaViewModel {
    func runLoadTask(
        _ operation: @escaping @MainActor (GenreMangaViewModel) async -> Void
    ) {
        loadTask?.cancel()
        loadTask = Task(priority: .utility) { [weak self] in
            guard let self else { return }
            await operation(self)
        }
    }
}

// MARK: - Loading Lifecycle

private extension GenreMangaViewModel {
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
            let genres = try await service.fetchMangaGenres().data
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

private extension GenreMangaViewModel {
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
            loadState = genreSections.isEmpty ? .error(FeatureLoadFailure(message: Self.genreErrorMessage)) : .loaded
        case .cancelled:
            break
        }
    }

    func applyPlaceholders(
        phase: MainCategoryGenreBatchPhase,
        genres: [MangaListGenreDTO]
    ) {
        let placeholderSections = genres.map { genre in
            MangaGenreSection(genre: genre, items: [])
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

private extension GenreMangaViewModel {
    func updateGenreSection(genreId: Int, items: [MangaListRandomDTO]) {
        guard let index = genreSections.firstIndex(where: { $0.genre.id == genreId }) else { return }
        genreSections[index] = MangaGenreSection(
            genre: genreSections[index].genre,
            items: items
        )
    }
}

// MARK: - Genre Mapping

private extension GenreMangaViewModel {
    func validLocalizedGenres(from genres: [MangaListGenreDTO]) -> [MangaListGenreDTO] {
        genres
            .filter { genre in
                guard let name = genre.name else { return false }
                return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            .map(localizedGenre)
    }

    func localizedGenre(_ genre: MangaListGenreDTO) -> MangaListGenreDTO {
        guard let englishName = genre.name else { return genre }
        let localizedName = MangaGenreLocalizationModel.localizedName(for: englishName)
        return MangaListGenreDTO(malId: genre.malId, name: localizedName)
    }
}

// MARK: - Item Fetching

private extension GenreMangaViewModel {
    func fetchGenreItemsWithRetry(genreId: Int) async -> [MangaListRandomDTO] {
        var attempt = 0
        while attempt <= Self.maxRetryCount {
            guard !Task.isCancelled else { return [] }
            do {
                let response = try await service.fetchMangaByGenre(
                    genreId: genreId,
                    limit: itemRequestLimit
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
