//
//  PeopleDetailService.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/23.
//

import Foundation

nonisolated protocol PeopleDetailServicing: Sendable {
    func fetchPeopleDetail(malId: Int) async throws -> PeopleDetailResponse
}

nonisolated final class PeopleDetailService: PeopleDetailServicing {

    private let apiService: JikanAPIServicing
    private let lifecycleScope: RequestLifecycleScope

    init(
        apiService: JikanAPIServicing,
        lifecycleScope: RequestLifecycleScope
    ) {
        self.apiService = apiService
        self.lifecycleScope = lifecycleScope
    }

    func fetchPeopleDetail(malId: Int) async throws -> PeopleDetailResponse {
        try await apiService.fetch(
            endpoint: APIConfig.People.full(id: malId),
            cachePolicy: .cacheFirst(ttl: 600),
            lifecycleScope: lifecycleScope
        )
    }
}
