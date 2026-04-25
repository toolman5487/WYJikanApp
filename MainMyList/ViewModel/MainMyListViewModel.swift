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

    func filteredItems(from items: [MyListCollectionItem]) -> [MyListCollectionItem] {
        guard let mediaKind = selectedFilter.mediaKind else { return items }
        return items.filter { $0.mediaKind == mediaKind }
    }

    func count(for mediaKind: MyListMediaKind, in items: [MyListCollectionItem]) -> Int {
        items.filter { $0.mediaKind == mediaKind }.count
    }

    func remove(_ item: MyListCollectionItem, from modelContext: ModelContext) {
        modelContext.delete(item)
        do {
            try modelContext.save()
        } catch {
            AppLogger.persistence.error("MyList delete failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func emptyTitle(for filter: Filter) -> String {
        filter == .all ? "還沒有收藏" : "還沒有收藏\(filter.title)"
    }
}
