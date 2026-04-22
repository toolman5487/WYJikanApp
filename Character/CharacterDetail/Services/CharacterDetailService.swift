//
//  CharacterDetailService.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/22.
//

import Foundation

protocol CharacterDetailServicing {
    func fetchCharacterDetail(malId: Int) async throws -> CharacterDetailResponse
}

final class CharacterDetailService: CharacterDetailServicing {

    private let apiService: JikanAPIService

    init(apiService: JikanAPIService = .shared) {
        self.apiService = apiService
    }

    func fetchCharacterDetail(malId: Int) async throws -> CharacterDetailResponse {
        try await apiService.fetch(endpoint: APIConfig.Characters.full(id: malId))
    }
}
