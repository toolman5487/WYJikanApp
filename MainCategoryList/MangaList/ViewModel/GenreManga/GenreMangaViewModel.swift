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
    enum LoadState: Equatable {
        case idle
        case loadingInitial
        case loadingMore
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
        case content(sections: [MangaGenreSection], inlineError: String?, loadMoreState: LoadMoreState)
    }

    private static let initialGenreSections = 12
    private static let loadMoreGenreSections = 12
    private static let genreMangaLimit = 5
    private static let maxRetryCount = 2
    private static let initialItemRequestDelay: Duration = .milliseconds(1200)
    private static let requestInterval: Duration = .seconds(1)
    private static let retryBackoff: Duration = .milliseconds(800)
    private static let genreErrorMessage = "目前無法載入分類資料，請稍後再試"

    @Published private(set) var genreSections: [MangaGenreSection] = []
    @Published private(set) var loadState: LoadState = .idle
    @Published private(set) var canLoadMore: Bool = false

    var screenState: ScreenState {
        switch loadState {
        case .loadingInitial where genreSections.isEmpty:
            return .loading
        case .error(let message) where genreSections.isEmpty:
            return .error(message)
        case .idle, .loadingInitial, .loadingMore, .loaded, .error:
            if genreSections.isEmpty {
                return .empty
            }

            let inlineError: String?
            if case .error(let message) = loadState {
                inlineError = message
            } else {
                inlineError = nil
            }

            let loadMoreState: LoadMoreState
            if !canLoadMore {
                loadMoreState = .hidden
            } else if loadState == .loadingMore {
                loadMoreState = .loading
            } else {
                loadMoreState = .available
            }

            return .content(
                sections: genreSections,
                inlineError: inlineError,
                loadMoreState: loadMoreState
            )
        }
    }

    private let service: MainCategoryListServicing

    private var loadTask: Task<Void, Never>?
    private var allLocalizedGenres: [MangaListGenreDTO] = []
    private var loadedGenreCount = 0

    init(service: MainCategoryListServicing = MainCategoryListService()) {
        self.service = service
    }

    func loadIfNeeded() {
        guard loadState == .idle, genreSections.isEmpty else { return }
        loadSections()
    }

    func loadSections() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }
            await self.fetchSections()
        }
    }

    func loadMoreSections() {
        switch loadState {
        case .loadingInitial, .loadingMore:
            return
        default:
            break
        }
        guard canLoadMore else { return }

        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }
            await self.fetchNextGenreBatch(isInitialLoad: false)
        }
    }

    func stop() {
        loadTask?.cancel()
        loadTask = nil
    }

    private func fetchSections() async {
        loadState = .loadingInitial
        canLoadMore = false
        genreSections = []
        allLocalizedGenres = []
        loadedGenreCount = 0

        do {
            let genres = try await service.fetchMangaGenres().data
            let validGenres = genres.filter { genre in
                guard let name = genre.name else { return false }
                return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            allLocalizedGenres = validGenres.map(localizedGenre)
            guard !allLocalizedGenres.isEmpty else {
                loadState = .loaded
                return
            }
            await fetchNextGenreBatch(isInitialLoad: true)
        } catch {
            guard !Task.isCancelled else { return }
            loadState = .error(message: Self.genreErrorMessage)
            canLoadMore = false
        }
    }

    private func fetchNextGenreBatch(isInitialLoad: Bool) async {
        loadState = isInitialLoad ? .loadingInitial : .loadingMore

        let batchSize = isInitialLoad ? Self.initialGenreSections : Self.loadMoreGenreSections
        let nextEndIndex = min(loadedGenreCount + batchSize, allLocalizedGenres.count)
        let batchGenres = Array(allLocalizedGenres[loadedGenreCount..<nextEndIndex])

        guard !batchGenres.isEmpty else {
            canLoadMore = false
            loadState = genreSections.isEmpty ? .error(message: Self.genreErrorMessage) : .loaded
            return
        }

        let placeholderSections = batchGenres.map { genre in
            MangaGenreSection(genre: genre, items: [])
        }

        if isInitialLoad {
            genreSections = placeholderSections
        } else {
            genreSections.append(contentsOf: placeholderSections)
        }

        try? await Task.sleep(for: Self.initialItemRequestDelay)
        guard !Task.isCancelled else { return }

        for genre in batchGenres {
            guard !Task.isCancelled else { return }
            let items = await fetchGenreItemsWithRetry(genreId: genre.id)
            guard !Task.isCancelled else { return }
            updateGenreSection(genreId: genre.id, items: items)
            try? await Task.sleep(for: Self.requestInterval)
        }

        loadedGenreCount = nextEndIndex
        canLoadMore = loadedGenreCount < allLocalizedGenres.count
        loadState = .loaded
    }

    private func localizedGenre(_ genre: MangaListGenreDTO) -> MangaListGenreDTO {
        guard let englishName = genre.name else { return genre }
        let localizedName = MangaGenreLocalizationModel.localizedName(for: englishName)
        return MangaListGenreDTO(malId: genre.malId, name: localizedName)
    }

    private func fetchGenreItemsWithRetry(genreId: Int) async -> [MangaListRandomDTO] {
        var attempt = 0
        while attempt <= Self.maxRetryCount {
            guard !Task.isCancelled else { return [] }
            do {
                let response = try await service.fetchMangaByGenre(
                    genreId: genreId,
                    limit: Self.genreMangaLimit
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

    private func updateGenreSection(genreId: Int, items: [MangaListRandomDTO]) {
        guard let index = genreSections.firstIndex(where: { $0.genre.id == genreId }) else { return }
        genreSections[index] = MangaGenreSection(
            genre: genreSections[index].genre,
            items: items
        )
    }
}
