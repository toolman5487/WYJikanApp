//
//  MainCategoryParentChromeStateObserver.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/15.
//

import Combine
import Foundation

// MARK: - MainCategoryParentChromeStateObserver

@MainActor
extension MainCategoryListViewModel {
    func makeParentChromeStateCancellable() -> AnyCancellable {
        let publishers = [
            animeParentChromeStatePublisher,
            mangaParentChromeStatePublisher,
            peopleParentChromeStatePublisher,
            characterParentChromeStatePublisher
        ]

        return Publishers.MergeMany(publishers)
            .receive(on: RunLoop.main)
            .sink { [weak self] kind in
                guard let self, self.selectedKind == kind else { return }
                self.objectWillChange.send()
            }
    }
}

// MARK: - Publishers

@MainActor
private extension MainCategoryListViewModel {
    var animeParentChromeStatePublisher: AnyPublisher<MainListKind, Never> {
        Publishers.CombineLatest(
            animeListViewModel.genreAnimeViewModel.$canLoadMore,
            animeListViewModel.genreAnimeViewModel.$loadState
        )
        .map { canLoadMore, loadState in
            MainCategoryParentChromeState(
                canLoadMore: canLoadMore && loadState.allowsPullLoadMore,
                isLoadingMore: loadState == .loadingMore,
                topFilterSelectionIdentifier: nil
            )
        }
        .removeDuplicates()
        .map { _ in MainListKind.anime }
        .eraseToAnyPublisher()
    }

    var mangaParentChromeStatePublisher: AnyPublisher<MainListKind, Never> {
        Publishers.CombineLatest(
            mangaListViewModel.genreMangaViewModel.$canLoadMore,
            mangaListViewModel.genreMangaViewModel.$loadState
        )
        .map { canLoadMore, loadState in
            MainCategoryParentChromeState(
                canLoadMore: canLoadMore && loadState.allowsPullLoadMore,
                isLoadingMore: loadState == .loadingMore,
                topFilterSelectionIdentifier: nil
            )
        }
        .removeDuplicates()
        .map { _ in MainListKind.manga }
        .eraseToAnyPublisher()
    }

    var peopleParentChromeStatePublisher: AnyPublisher<MainListKind, Never> {
        Publishers.CombineLatest3(
            peopleListViewModel.$hasNextPage,
            peopleListViewModel.$paginationState,
            peopleListViewModel.$selectedSort
        )
        .map { hasNextPage, paginationState, selectedSort in
            MainCategoryParentChromeState(
                canLoadMore: hasNextPage && paginationState == .idle,
                isLoadingMore: paginationState == .loadingMore,
                topFilterSelectionIdentifier: selectedSort.rawValue
            )
        }
        .removeDuplicates()
        .map { _ in MainListKind.people }
        .eraseToAnyPublisher()
    }

    var characterParentChromeStatePublisher: AnyPublisher<MainListKind, Never> {
        Publishers.CombineLatest3(
            characterListViewModel.$hasNextPage,
            characterListViewModel.$paginationState,
            characterListViewModel.$selectedSort
        )
        .map { hasNextPage, paginationState, selectedSort in
            MainCategoryParentChromeState(
                canLoadMore: hasNextPage && paginationState == .idle,
                isLoadingMore: paginationState == .loadingMore,
                topFilterSelectionIdentifier: selectedSort.rawValue
            )
        }
        .removeDuplicates()
        .map { _ in MainListKind.character }
        .eraseToAnyPublisher()
    }
}

// MARK: - MainCategoryParentChromeState

private struct MainCategoryParentChromeState: Equatable {
    let canLoadMore: Bool
    let isLoadingMore: Bool
    let topFilterSelectionIdentifier: String?
}

private extension GenreAnimeViewModel.LoadState {
    var allowsPullLoadMore: Bool {
        switch self {
        case .loadingMore:
            return false
        case .error:
            return false
        case .idle:
            return true
        case .loadingInitial:
            return true
        case .paused:
            return true
        case .loaded:
            return true
        }
    }
}

private extension GenreMangaViewModel.LoadState {
    var allowsPullLoadMore: Bool {
        switch self {
        case .loadingMore:
            return false
        case .error:
            return false
        case .idle:
            return true
        case .loadingInitial:
            return true
        case .paused:
            return true
        case .loaded:
            return true
        }
    }
}
