//
//  MainMyListViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import Combine
import OSLog
import SwiftData

@MainActor
final class MainMyListViewModel: ObservableObject {
    struct Presentation {
        let filteredItems: [MyListCollectionItem]
        let totalCount: Int
        let animeCount: Int
        let mangaCount: Int
    }

    enum Filter: String, CaseIterable, Identifiable {
        case all
        case anime
        case manga

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "全部"
            case .anime: return "動畫"
            case .manga: return "漫畫"
            }
        }

        var mediaKind: MyListMediaKind? {
            switch self {
            case .all: return nil
            case .anime: return .anime
            case .manga: return .manga
            }
        }
    }

    @Published var selectedFilter: Filter = .all
    private let favoriteRepository: any FavoriteRepository

    init(favoriteRepository: any FavoriteRepository = SwiftDataFavoriteRepository.shared) {
        self.favoriteRepository = favoriteRepository
    }

    func makePresentation(from items: [MyListCollectionItem]) -> Presentation {
        let selectedMediaKind = selectedFilter.mediaKind
        var animeCount = 0
        var mangaCount = 0
        var filteredItems: [MyListCollectionItem] = []
        filteredItems.reserveCapacity(items.count)

        for item in items {
            switch item.mediaKind {
            case .anime:
                animeCount += 1
            case .manga:
                mangaCount += 1
            }

            if selectedMediaKind == nil || selectedMediaKind == item.mediaKind {
                filteredItems.append(item)
            }
        }

        return Presentation(
            filteredItems: filteredItems,
            totalCount: items.count,
            animeCount: animeCount,
            mangaCount: mangaCount
        )
    }

    func remove(_ item: MyListCollectionItem, from modelContext: ModelContext) {
        do {
            try favoriteRepository.remove(item, from: modelContext)
        } catch {
            AppLogger.persistence.error("MyList delete failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func emptyTitle(for filter: Filter) -> String {
        filter == .all ? "還沒有收藏" : "還沒有收藏\(filter.title)"
    }
}
