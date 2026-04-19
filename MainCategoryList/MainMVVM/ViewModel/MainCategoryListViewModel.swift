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

    @Published var selectedKind: MainListKind = .anime

    private var cancellables = Set<AnyCancellable>()

    init(
        animeListViewModel: AnimeListViewModel = AnimeListViewModel(),
        mangaListViewModel: MangaListViewModel = MangaListViewModel()
    ) {
        self.animeListViewModel = animeListViewModel
        self.mangaListViewModel = mangaListViewModel

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
        case .people, .character:
            break
        }
    }

    func reloadSelectedKind() {
        switch selectedKind {
        case .anime:
            animeListViewModel.reload()
        case .manga:
            mangaListViewModel.reload()
        case .people, .character:
            break
        }
    }

    func stopLoading() {
        animeListViewModel.stop()
        mangaListViewModel.stop()
    }
}
