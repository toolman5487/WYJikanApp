//
//  HomeTrendingViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import Combine
import Foundation

@MainActor
final class HomeTrendingViewModel: ObservableObject {
    private static let maxCards = 10

    @Published private(set) var items: [HomeTrendingCardItem] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private let service: MainHomeServicing
    private var loadTask: Task<Void, Never>?

    init(service: MainHomeServicing = MainHomeService()) {
        self.service = service
    }

    func loadIfNeeded() {
        guard items.isEmpty, !isLoading else { return }
        load()
    }

    func load() {
        loadTask?.cancel()
        isLoading = true
        errorMessage = nil

        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let response = try await self.service.fetchTopAnime(limit: Self.maxCards)
                let mapped: [HomeTrendingCardItem] = response.data.compactMap { dto -> HomeTrendingCardItem? in
                    guard let urlString =
                        dto.images?.webp?.largeImageUrl ??
                        dto.images?.jpg?.largeImageUrl ??
                        dto.images?.webp?.imageUrl ??
                        dto.images?.jpg?.imageUrl,
                        let url = URL(string: urlString) else { return nil }

                    return HomeTrendingCardItem(
                        id: dto.malId,
                        rank: dto.rank,
                        imageURL: url
                    )
                }

                self.items = mapped
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.items = []
                self.isLoading = false
            }
        }
    }

    func stop() {
        loadTask?.cancel()
        loadTask = nil
    }
}
