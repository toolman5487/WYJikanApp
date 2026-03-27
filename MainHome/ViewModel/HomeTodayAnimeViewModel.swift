//
//  HomeTodayAnimeViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import Combine
import Foundation

@MainActor
final class HomeTodayAnimeViewModel: ObservableObject {
    private static let maxCards = 10

    @Published private(set) var items: [HomeTodayAnimeCardItem] = []
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
                let response = try await self.service.fetchTodayAnime(limit: Self.maxCards)
                let mapped: [HomeTodayAnimeCardItem] = response.data.compactMap { dto -> HomeTodayAnimeCardItem? in
                    guard let urlString =
                        dto.images?.jpg?.largeImageUrl ??
                        dto.images?.webp?.largeImageUrl ??
                        dto.images?.jpg?.imageUrl ??
                        dto.images?.webp?.imageUrl,
                        let url = URL(string: urlString) else { return nil }

                    return HomeTodayAnimeCardItem(
                        id: dto.malId,
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
