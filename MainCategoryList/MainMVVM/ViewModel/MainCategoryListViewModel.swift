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

    func stopLoading() {
        animeListViewModel.stop()
        mangaListViewModel.stop()
        peopleListViewModel.stop()
        characterListViewModel.stop()
    }
}
