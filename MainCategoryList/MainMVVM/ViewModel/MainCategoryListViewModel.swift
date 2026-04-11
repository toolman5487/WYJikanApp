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

    init(
        animeListViewModel: AnimeListViewModel = AnimeListViewModel(),
        mangaListViewModel: MangaListViewModel = MangaListViewModel()
    ) {
        self.animeListViewModel = animeListViewModel
        self.mangaListViewModel = mangaListViewModel
    }

    func loadIfNeeded(for kind: MainListKind) {
        switch kind {
        case .anime:
            animeListViewModel.loadIfNeeded()
        case .manga:
            mangaListViewModel.loadIfNeeded()
        case .people, .character:
            break
        }
    }

    func stopLoading() {
        animeListViewModel.stop()
        mangaListViewModel.stop()
    }
}
