//
//  HomeTrendingViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import Combine
import Foundation

enum HomeTrendingAnimeViewState: Equatable {
    case loading
    case failed(String)
    case empty
    case loaded
}

@MainActor
final class HomeTrendingAnimeViewModel: ObservableObject {
    private static let maxCards = 10

    @Published private(set) var items: [HomeTrendingAnimeCardItem] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private let service: MainHomeServicing
    private var loadTask: Task<Void, Never>?

    init(service: MainHomeServicing = MainHomeService()) {
        self.service = service
    }

    var viewState: HomeTrendingAnimeViewState {
        if isLoading {
            return .loading
        }
        if let errorMessage {
            return .failed(errorMessage)
        }
        if items.isEmpty {
            return .empty
        }
        return .loaded
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
                let mapped: [HomeTrendingAnimeCardItem] = response.data.compactMap { dto -> HomeTrendingAnimeCardItem? in
                    guard let urlString =
                        dto.images?.webp?.largeImageUrl ??
                        dto.images?.jpg?.largeImageUrl ??
                        dto.images?.webp?.imageUrl ??
                        dto.images?.jpg?.imageUrl,
                        let url = URL(string: urlString) else { return nil }

                    return HomeTrendingAnimeCardItem(
                        id: dto.malId,
                        title: Self.displayTitle(
                            japanese: dto.titleJapanese,
                            english: dto.titleEnglish,
                            fallback: dto.title
                        ),
                        type: dto.type,
                        score: dto.score,
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

    private static func displayTitle(japanese: String?, english: String?, fallback: String?) -> String {
        if let japanese, !japanese.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return japanese
        }
        if let english, !english.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return english
        }
        if let fallback, !fallback.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return fallback
        }
        return "未命名作品"
    }
}
