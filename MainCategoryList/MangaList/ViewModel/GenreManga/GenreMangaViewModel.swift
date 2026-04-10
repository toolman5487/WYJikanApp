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
        case failed(message: String)
    }

    private static let initialGenreSections = 12
    private static let loadMoreGenreSections = 12
    private static let genreMangaLimit = 10
    private static let maxRetryCount = 2
    private static let requestIntervalNanoseconds: UInt64 = 400_000_000
    private static let retryBackoffNanoseconds: UInt64 = 800_000_000
    private static let genreErrorMessage = "目前無法載入分類資料，請稍後再試"

    @Published private(set) var genreSections: [MangaGenreSection] = []
    @Published private(set) var loadState: LoadState = .idle
    @Published private(set) var canLoadMore: Bool = false

    var isLoading: Bool {
        if case .loadingInitial = loadState {
            return true
        }
        return false
    }

    var isLoadingMore: Bool {
        if case .loadingMore = loadState {
            return true
        }
        return false
    }

    var errorMessage: String? {
        if case .failed(let message) = loadState {
            return message
        }
        return nil
    }

    private let service: MainCategoryListServicing

    private var loadTask: Task<Void, Never>?
    private var allLocalizedGenres: [MangaListGenreDTO] = []
    private var loadedGenreCount = 0

    init(service: MainCategoryListServicing = MainCategoryListService()) {
        self.service = service
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
            await fetchNextGenreBatch(isInitialLoad: true)
        } catch {
            guard !Task.isCancelled else { return }
            loadState = .failed(message: Self.genreErrorMessage)
            canLoadMore = false
        }
    }

    private func fetchNextGenreBatch(isInitialLoad: Bool) async {
        loadState = isInitialLoad ? .loadingInitial : .loadingMore

        let batchSize = isInitialLoad ? Self.initialGenreSections : Self.loadMoreGenreSections
        let nextEndIndex = min(loadedGenreCount + batchSize, allLocalizedGenres.count)
        let batchGenres = Array(allLocalizedGenres[loadedGenreCount..<nextEndIndex])

        for genre in batchGenres {
            guard !Task.isCancelled else { return }
            let items = await fetchGenreItemsWithRetry(genreId: genre.id)
            guard !Task.isCancelled else { return }
            if !items.isEmpty {
                genreSections.append(
                    MangaGenreSection(
                        genre: genre,
                        items: items
                    )
                )
            }
            try? await Task.sleep(nanoseconds: Self.requestIntervalNanoseconds)
        }

        loadedGenreCount = nextEndIndex
        canLoadMore = loadedGenreCount < allLocalizedGenres.count
        loadState = genreSections.isEmpty ? .failed(message: Self.genreErrorMessage) : .loaded
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
                try? await Task.sleep(nanoseconds: Self.retryBackoffNanoseconds * UInt64(attempt))
            }
        }
        return []
    }
}
