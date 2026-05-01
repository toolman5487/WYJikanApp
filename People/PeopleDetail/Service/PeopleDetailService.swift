//
//  PeopleDetailService.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/23.
//

import Foundation

protocol PeopleDetailServicing {
    func fetchPeopleDetail(malId: Int) async throws -> PeopleDetailResponse
}

final class PeopleDetailService: PeopleDetailServicing {

    private let apiService: JikanAPIServicing

    init(apiService: JikanAPIServicing = JikanAPIService.shared) {
        self.apiService = apiService
    }

    func fetchPeopleDetail(malId: Int) async throws -> PeopleDetailResponse {
        try await apiService.fetch(
            endpoint: APIConfig.People.full(id: malId),
            cachePolicy: .cacheFirst(ttl: 600)
        )
    }
}
