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
    
    // MARK: - Published State

    @Published private(set) var randomHeroViewModel: RandomHeroViewModel

    // MARK: - Lifecycle

    init(
        randomHeroViewModel: RandomHeroViewModel = RandomHeroViewModel()
    ) {
        self.randomHeroViewModel = randomHeroViewModel
    }

    // MARK: - Public Methods

    func stop() {
        randomHeroViewModel.stop()
    }
}
