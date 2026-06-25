//
//  MangaListViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/10.
//

import Foundation
import Combine

@MainActor
final class MangaListViewModel: ObservableObject, MainCategoryListKindLoadControlling {
    let genreMangaViewModel: GenreMangaViewModel

    init(genreMangaViewModel: GenreMangaViewModel) {
        self.genreMangaViewModel = genreMangaViewModel
    }

    func configureGenreBatchIfNeeded(_ configuration: MainCategoryGenreBatchConfiguration) {
        genreMangaViewModel.configureBatchIfNeeded(configuration)
    }

    func loadIfNeeded() {
        genreMangaViewModel.loadIfNeeded()
    }

    func reload() {
        genreMangaViewModel.loadSections()
    }

    func stop() {
        genreMangaViewModel.stop()
    }

    func loadMore() {
        genreMangaViewModel.loadMoreSections()
    }

    var canLoadMore: Bool {
        genreMangaViewModel.canPullLoadMore
    }

    var isLoadingMore: Bool {
        genreMangaViewModel.isLoadingMore
    }
}
