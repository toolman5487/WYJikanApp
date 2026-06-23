//
//  CharacterDetailService.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/22.
//

import Foundation

nonisolated protocol CharacterDetailServicing: Sendable {
    func fetchCharacterDetail(malId: Int) async throws -> CharacterDetailResponse
}

nonisolated final class CharacterDetailService: CharacterDetailServicing {

    private let apiService: JikanAPIServicing
    private let lifecycleScope: RequestLifecycleScope

    init(
        apiService: JikanAPIServicing,
        lifecycleScope: RequestLifecycleScope
    ) {
        self.apiService = apiService
        self.lifecycleScope = lifecycleScope
    }

    func fetchCharacterDetail(malId: Int) async throws -> CharacterDetailResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Characters.full(id: malId),
            cachePolicy: .detail(),
            lifecycleScope: lifecycleScope
        )
    }
}
