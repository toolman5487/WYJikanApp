//
//  AnimeListViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import Foundation
import Combine

@MainActor
final class AnimeListViewModel: ObservableObject, PaginatedListLoadControlling {
    // MARK: - Properties

    let genreAnimeViewModel: GenreAnimeViewModel

    // MARK: - Lifecycle

    init(genreAnimeViewModel: GenreAnimeViewModel) {
        self.genreAnimeViewModel = genreAnimeViewModel
    }

    // MARK: - Public Methods

    func configureGenreBatchIfNeeded(_ configuration: MainCategoryGenreBatchConfiguration) {
        genreAnimeViewModel.configureBatchIfNeeded(configuration)
    }

    func loadIfNeeded() {
        genreAnimeViewModel.loadIfNeeded()
    }

    func reload() {
        genreAnimeViewModel.loadSections()
    }

    func stop() {
        genreAnimeViewModel.stop()
    }

    func loadMore() {
        genreAnimeViewModel.loadMoreSections()
    }

    var canLoadMore: Bool {
        genreAnimeViewModel.canLoadMore
    }

    var isLoadingMore: Bool {
        genreAnimeViewModel.isLoadingMore
    }
}
