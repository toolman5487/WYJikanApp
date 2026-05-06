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
    case content([HomeTrendingMangaCardItem])
}

@MainActor
final class HomeTrendingMangaViewModel: ObservableObject {
    private static let maxCards = 10

    @Published private(set) var screenState: HomeTrendingMangaScreenState = .loading

    private let service: MainHomeServicing
    private var loadTask: Task<Void, Never>?
    private var isLoading = false

    init(service: MainHomeServicing = MainHomeService()) {
        self.service = service
    }

    var items: [HomeTrendingMangaCardItem] {
        switch screenState {
        case .content(let items):
            return items
        case .loading, .error, .empty:
            return []
        }
    }

    func loadIfNeeded() {
        guard items.isEmpty, !isLoading else { return }
        load()
    }

    func load() {
        loadTask?.cancel()
        isLoading = true
        screenState = .loading

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

                self.isLoading = false
                self.screenState = mapped.isEmpty ? .empty : .content(mapped)
            } catch {
                self.isLoading = false
                self.screenState = .error(error.localizedDescription)
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
