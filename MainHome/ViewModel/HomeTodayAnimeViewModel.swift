//
//  HomeTodayAnimeViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import Combine
import Foundation

enum HomeTodayAnimeScreenState: Equatable {
    case loading
    case error(String)
    case empty
    case content([HomeTodayAnimeCardItem])
}

@MainActor
final class HomeTodayAnimeViewModel: ObservableObject {
    private static let maxCards = 10
    private static let scheduleFetchLimit = 25

    @Published private(set) var screenState: HomeTodayAnimeScreenState = .loading

    private let service: MainHomeServicing
    private var loadTask: Task<Void, Never>?
    private var isLoading = false

    init(service: MainHomeServicing = MainHomeService()) {
        self.service = service
    }

    var items: [HomeTodayAnimeCardItem] {
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
                let response = try await self.service.fetchTodayAnime(limit: Self.scheduleFetchLimit)
                let mapped: [HomeTodayAnimeCardItem] = response.data.compactMap { dto -> HomeTodayAnimeCardItem? in
                    guard let urlString =
                        dto.images?.jpg?.largeImageUrl ??
                        dto.images?.webp?.largeImageUrl ??
                        dto.images?.jpg?.imageUrl ??
                        dto.images?.webp?.imageUrl,
                        let url = URL(string: urlString) else { return nil }

                    return HomeTodayAnimeCardItem(
                        id: dto.malId,
                        title: Self.displayTitle(
                            japanese: dto.titleJapanese,
                            english: dto.titleEnglish,
                            fallback: dto.title
                        ),
                        type: dto.type,
                        score: dto.score,
                        imageURL: url
                    )
                }

                var seenIDs = Set<Int>()
                let uniqueInOrder = mapped.filter { seenIDs.insert($0.id).inserted }
                let items = Array(uniqueInOrder.prefix(Self.maxCards))
                self.isLoading = false
                self.screenState = items.isEmpty ? .empty : .content(items)
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
