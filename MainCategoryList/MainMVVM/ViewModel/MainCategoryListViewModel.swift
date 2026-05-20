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
    }

    private func bindSelectedKind() {
        $selectedKind
            .removeDuplicates()
            .sink { [weak self] kind in
                self?.loadIfNeeded(for: kind)
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
