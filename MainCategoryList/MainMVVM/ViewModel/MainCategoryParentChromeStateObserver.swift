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
            animeListViewModel.genreAnimeViewModel.$hasNextPage,
            animeListViewModel.genreAnimeViewModel.$loadState
        )
        .map { hasNextPage, loadState in
            MainCategoryParentChromeState(
                canLoadMore: hasNextPage && loadState.permitsLoadMore,
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
            mangaListViewModel.genreMangaViewModel.$hasNextPage,
            mangaListViewModel.genreMangaViewModel.$loadState
        )
        .map { hasNextPage, loadState in
            MainCategoryParentChromeState(
                canLoadMore: hasNextPage && loadState.permitsLoadMore,
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
            peopleListViewModel.$loadState,
            peopleListViewModel.$selectedSort
        )
        .map { hasNextPage, loadState, selectedSort in
            MainCategoryParentChromeState(
                canLoadMore: hasNextPage && loadState.permitsLoadMore,
                isLoadingMore: loadState == .loadingMore,
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
            characterListViewModel.$loadState,
            characterListViewModel.$selectedSort
        )
        .map { hasNextPage, loadState, selectedSort in
            MainCategoryParentChromeState(
                canLoadMore: hasNextPage && loadState.permitsLoadMore,
                isLoadingMore: loadState == .loadingMore,
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
