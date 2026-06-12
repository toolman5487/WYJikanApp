//
//  PaginatedListState.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/9.
//

import Foundation

nonisolated enum PaginationFooterState: Equatable, Sendable {
    case hidden
    case available
    case loading
    case error(FeatureLoadFailure)
}

nonisolated struct PaginatedPage<Item: Sendable>: Sendable {
    let items: [Item]
    let currentPage: Int
    let hasNextPage: Bool
}

nonisolated struct PaginatedListState<Item: Identifiable & Sendable>: Sendable where Item.ID: Hashable & Sendable {
    private(set) var items: [Item] = []
    private(set) var currentPage = 0
    private(set) var hasLoaded = false
    private(set) var hasNextPage = false
    private(set) var isLoadingMore = false
    private(set) var footerState: PaginationFooterState = .hidden

    private var requestGeneration = 0

    var canLoadMore: Bool {
        hasLoaded && hasNextPage && !isLoadingMore
    }

    mutating func beginReload(clearItems: Bool) -> Int {
        requestGeneration += 1
        currentPage = 0
        hasNextPage = false
        isLoadingMore = false
        footerState = .hidden

        if clearItems {
            items = []
        }

        return requestGeneration
    }

    mutating func finishReload(_ page: PaginatedPage<Item>, generation: Int) -> Bool {
        guard isCurrent(generation) else { return false }

        hasLoaded = true
        currentPage = page.currentPage
        hasNextPage = page.hasNextPage
        items = deduplicated(page.items)
        footerState = resolvedFooterState()

        return true
    }

    mutating func beginLoadMore() -> Int? {
        guard canLoadMore else { return nil }

        isLoadingMore = true
        footerState = .loading
        return requestGeneration
    }

    mutating func finishLoadMore(
        _ page: PaginatedPage<Item>,
        generation: Int,
        requiresNewItemsForNextPage: Bool = false
    ) -> Bool {
        guard isCurrent(generation) else { return false }

        let mergedItems = deduplicated(items + page.items)
        let appendedNewItems = mergedItems.count > items.count

        currentPage = page.currentPage
        hasNextPage = page.hasNextPage && (!requiresNewItemsForNextPage || appendedNewItems)
        items = mergedItems
        isLoadingMore = false
        footerState = resolvedFooterState()

        return true
    }

    mutating func cancelLoadMore(generation: Int) -> Bool {
        guard isCurrent(generation) else { return false }

        isLoadingMore = false
        footerState = resolvedFooterState()

        return true
    }

    mutating func failLoadMore(_ failure: FeatureLoadFailure, generation: Int) -> Bool {
        guard isCurrent(generation) else { return false }

        isLoadingMore = false
        footerState = .error(failure)

        return true
    }

    func isCurrent(_ generation: Int) -> Bool {
        generation == requestGeneration
    }

    func shouldLoadMore(after item: Item, visibleItems: [Item], threshold: Int = 5) -> Bool {
        guard canLoadMore else { return false }
        guard let index = visibleItems.firstIndex(where: { $0.id == item.id }) else { return false }

        return index >= max(visibleItems.count - threshold, 0)
    }

    private func resolvedFooterState() -> PaginationFooterState {
        if isLoadingMore {
            return .loading
        }

        if case .error(let failure) = footerState {
            return .error(failure)
        }

        return hasNextPage ? .available : .hidden
    }

    private func deduplicated(_ items: [Item]) -> [Item] {
        var seenIDs: Set<Item.ID> = []
        return items.filter { item in
            seenIDs.insert(item.id).inserted
        }
    }
}
