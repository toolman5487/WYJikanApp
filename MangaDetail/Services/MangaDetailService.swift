//
//  MangaDetailService.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/1.
//

import Foundation

protocol MangaDetailServicing {
    func fetchMangaDetail(malId: Int) async throws -> MangaDetailResponse
}

final class MangaDetailService: MangaDetailServicing {

    private let apiService: JikanAPIService

    init(apiService: JikanAPIService = .shared) {
        self.apiService = apiService
    }

    func fetchMangaDetail(malId: Int) async throws -> MangaDetailResponse {
        try await apiService.fetch(endpoint: APIConfig.Manga.detail(id: malId))
    }
}
