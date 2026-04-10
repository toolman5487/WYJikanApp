//
//  MangaListViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/10.
//

import Foundation
import Combine

@MainActor
final class MangaListViewModel: ObservableObject {
    let randomHeroViewModel: RandomMangaViewModel
    let genreMangaViewModel: GenreMangaViewModel

    init(
        randomHeroViewModel: RandomMangaViewModel = RandomMangaViewModel(),
        genreMangaViewModel: GenreMangaViewModel = GenreMangaViewModel()
    ) {
        self.randomHeroViewModel = randomHeroViewModel
        self.genreMangaViewModel = genreMangaViewModel
    }

    func stop() {
        randomHeroViewModel.stop()
        genreMangaViewModel.stop()
    }
}
