//
//  TrendingMangaViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import Combine
import Foundation

enum HomeTrendingMangaScreenState: Equatable {
    case loading
    case error(String)
    case empty
    case content
}

@MainActor
final class HomeTrendingMangaViewModel: ObservableObject {
    private static let maxCards = 10

    @Published private(set) var items: [HomeTrendingMangaCardItem] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private let service: MainHomeServicing
    private var loadTask: Task<Void, Never>?

    init(service: MainHomeServicing = MainHomeService()) {
        self.service = service
    }

    var screenState: HomeTrendingMangaScreenState {
        if isLoading {
            return .loading
        }
        if let errorMessage {
            return .error(errorMessage)
        }
        if items.isEmpty {
            return .empty
        }
        return .content
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
                let response = try await self.service.fetchTopManga(limit: Self.maxCards)

                let mapped: [HomeTrendingMangaCardItem] = response.data.compactMap { dto -> HomeTrendingMangaCardItem? in
                    guard let urlString = dto.imgUrl,
                          let url = URL(string: urlString) else { return nil }

                    return HomeTrendingMangaCardItem(
                        id: dto.id,
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
