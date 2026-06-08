//
//  MainCategoryListViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import Foundation
import Combine

@MainActor
final class MainCategoryListViewModel: ObservableObject {
    let animeListViewModel: AnimeListViewModel
    let mangaListViewModel: MangaListViewModel
    let peopleListViewModel: PeopleListViewModel
    let characterListViewModel: CharacterListViewModel

    @Published var selectedKind: MainListKind = .anime

    private var cancellables = Set<AnyCancellable>()

    init(
        animeListViewModel: AnimeListViewModel = AnimeListViewModel(),
        mangaListViewModel: MangaListViewModel = MangaListViewModel(),
        peopleListViewModel: PeopleListViewModel = PeopleListViewModel(),
        characterListViewModel: CharacterListViewModel = CharacterListViewModel()
    ) {
        self.animeListViewModel = animeListViewModel
        self.mangaListViewModel = mangaListViewModel
        self.peopleListViewModel = peopleListViewModel
        self.characterListViewModel = characterListViewModel

        bindSelectedKind()
        bindChildViewModels()
    }

    private func bindSelectedKind() {
        $selectedKind
            .removeDuplicates()
            .sink { [weak self] kind in
                self?.loadIfNeeded(for: kind)
            }
            .store(in: &cancellables)
    }

    private func bindChildViewModels() {
        Publishers.MergeMany(
            animeListViewModel.genreAnimeViewModel.objectWillChange.map { _ in },
            mangaListViewModel.genreMangaViewModel.objectWillChange.map { _ in },
            peopleListViewModel.objectWillChange.map { _ in },
            characterListViewModel.objectWillChange.map { _ in }
        )
        .sink { [weak self] in
            self?.objectWillChange.send()
        }
        .store(in: &cancellables)
    }

    private func loadIfNeeded(for kind: MainListKind) {
        switch kind {
        case .anime:
            animeListViewModel.loadIfNeeded()
        case .manga:
            mangaListViewModel.loadIfNeeded()
        case .people:
            peopleListViewModel.loadIfNeeded()
        case .character:
            characterListViewModel.loadIfNeeded()
        }
    }

    func reloadSelectedKind() {
        switch selectedKind {
        case .anime:
            animeListViewModel.reload()
        case .manga:
            mangaListViewModel.reload()
        case .people:
            peopleListViewModel.reload()
        case .character:
            characterListViewModel.reload()
        }
    }

    var canLoadMoreSelectedKind: Bool {
        switch selectedKind {
        case .anime:
            return animeListViewModel.genreAnimeViewModel.canLoadMore &&
                !animeListViewModel.genreAnimeViewModel.isLoadingMore
        case .manga:
            return mangaListViewModel.genreMangaViewModel.canLoadMore &&
                !mangaListViewModel.genreMangaViewModel.isLoadingMore
        case .people:
            return peopleListViewModel.hasNextPage && peopleListViewModel.paginationState != .loadingMore
        case .character:
            return characterListViewModel.hasNextPage && characterListViewModel.paginationState != .loadingMore
        }
    }

    var shouldShowLoadMoreFooter: Bool {
        canLoadMoreSelectedKind || isLoadingMoreSelectedKind
    }

    var isLoadingMoreSelectedKind: Bool {
        switch selectedKind {
        case .anime:
            return animeListViewModel.genreAnimeViewModel.isLoadingMore
        case .manga:
            return mangaListViewModel.genreMangaViewModel.isLoadingMore
        case .people:
            return peopleListViewModel.paginationState == .loadingMore
        case .character:
            return characterListViewModel.paginationState == .loadingMore
        }
    }

    var loadMoreFooterTitle: String {
        switch selectedKind {
        case .anime, .manga:
            return "載入更多種類"
        case .people:
            return "載入更多聲優"
        case .character:
            return "載入更多角色"
        }
    }

    var loadMoreFooterSubtitle: String {
        switch selectedKind {
        case .anime:
            return "繼續往下拉探索更多動畫分類"
        case .manga:
            return "繼續往下拉探索更多漫畫分類"
        case .people:
            return "繼續往下拉探索更多聲優"
        case .character:
            return "繼續往下拉探索更多角色"
        }
    }

    func loadMoreSelectedKind() {
        switch selectedKind {
        case .anime:
            animeListViewModel.genreAnimeViewModel.loadMoreSections()
        case .manga:
            mangaListViewModel.genreMangaViewModel.loadMoreSections()
        case .people:
            peopleListViewModel.loadMore()
        case .character:
            characterListViewModel.loadMore()
        }
    }

    var topFilterState: MainCategoryTopFilterState {
        switch selectedKind {
        case .anime, .manga:
            return .hidden

        case .people:
            return .menu(
                MainCategoryTopFilterMenu(
                    accessibilityValue: peopleListViewModel.selectedSort.title,
                    selectionIdentifier: peopleListViewModel.selectedSort.rawValue,
                    options: PeopleListSort.allCases.map(MainCategoryTopFilterOption.people)
                )
            )

        case .character:
            return .menu(
                MainCategoryTopFilterMenu(
                    accessibilityValue: characterListViewModel.selectedSort.title,
                    selectionIdentifier: characterListViewModel.selectedSort.rawValue,
                    options: CharacterListSort.allCases.map(MainCategoryTopFilterOption.character)
                )
            )
        }
    }

    var activeTopFilterSelectionIdentifier: String? {
        switch topFilterState {
        case .hidden:
            return nil
        case .menu(let menu):
            return menu.selectionIdentifier
        }
    }

    func selectTopFilterOption(_ option: MainCategoryTopFilterOption) {
        switch option {
        case .people(let sort):
            peopleListViewModel.selectSort(sort)
        case .character(let sort):
            characterListViewModel.selectSort(sort)
        }
    }

    func stopLoading() {
        animeListViewModel.stop()
        mangaListViewModel.stop()
        peopleListViewModel.stop()
        characterListViewModel.stop()
    }
}
