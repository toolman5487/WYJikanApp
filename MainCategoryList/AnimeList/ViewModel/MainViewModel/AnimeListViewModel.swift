//
//  AnimeListViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import Foundation
import Combine

@MainActor
final class AnimeListViewModel: ObservableObject {
    // MARK: - Properties

    let randomHeroViewModel: RandomHeroViewModel
    let genreAnimeViewModel: GenreAnimeViewModel

    // MARK: - Lifecycle

    init(
        randomHeroViewModel: RandomHeroViewModel,
        genreAnimeViewModel: GenreAnimeViewModel
    ) {
        self.randomHeroViewModel = randomHeroViewModel
        self.genreAnimeViewModel = genreAnimeViewModel
    }

    // MARK: - Public Methods

    func configureGenreBatchIfNeeded(_ configuration: MainCategoryGenreBatchConfiguration) {
        genreAnimeViewModel.configureBatchIfNeeded(configuration)
    }

    func loadIfNeeded() {
        randomHeroViewModel.loadIfNeeded()
        genreAnimeViewModel.loadIfNeeded()
    }

    func reload() {
        genreAnimeViewModel.loadSections()
    }

    func stop() {
        randomHeroViewModel.stop()
        genreAnimeViewModel.stop()
    }
}
