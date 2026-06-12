//
//  MainSearchPaginationState.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/2.
//

import Foundation

enum MainSearchRequestState: Equatable, Sendable {
    case idle
    case searching
    case loadingMore
    case loadMoreError(FeatureLoadFailure)

    var canStartLoadMore: Bool {
        switch self {
        case .idle, .loadMoreError:
            return true
        case .searching, .loadingMore:
            return false
        }
    }
}

struct MainSearchPaginationState: Sendable {
    private(set) var unsortedRows: [MainSearchResultRow] = []
    private(set) var currentPage = 0
    private(set) var hasNextPage = false
    private(set) var loadMoreTriggerIDs = Set<String>()
    private(set) var requestState: MainSearchRequestState = .idle
    private(set) var activeIntent: MainSearchIntent?

    var canStartLoadMore: Bool {
        requestState.canStartLoadMore
    }

    var nextPage: Int {
        currentPage + 1
    }

    func shouldLoadMore(currentRow: MainSearchResultRow) -> Bool {
        hasNextPage
            && canStartLoadMore
            && loadMoreTriggerIDs.contains(currentRow.id)
    }

    mutating func reset() {
        activeIntent = nil
        currentPage = 0
        hasNextPage = false
        loadMoreTriggerIDs = []
        unsortedRows = []
        requestState = .idle
    }

    mutating func startSearching(clearExistingRows: Bool) {
        if clearExistingRows {
            activeIntent = nil
            currentPage = 0
            hasNextPage = false
            unsortedRows = []
            loadMoreTriggerIDs = []
        }
        requestState = .searching
    }

    mutating func finishSearch(intent: MainSearchIntent, page: MainSearchPage) {
        activeIntent = intent
        currentPage = page.currentPage
        hasNextPage = page.hasNextPage
        unsortedRows = page.rows
        requestState = .idle
    }

    mutating func failSearch() {
        activeIntent = nil
        currentPage = 0
        hasNextPage = false
        loadMoreTriggerIDs = []
        unsortedRows = []
        requestState = .idle
    }

    mutating func startLoadingMore() {
        requestState = .loadingMore
    }

    mutating func finishLoadMore(page: MainSearchPage) {
        currentPage = page.currentPage
        hasNextPage = page.hasNextPage
        unsortedRows += page.rows
        requestState = .idle
    }

    mutating func failLoadMore(_ failure: FeatureLoadFailure) {
        requestState = .loadMoreError(failure)
    }

    mutating func updateLoadMoreTriggers(from sortedRows: [MainSearchResultRow]) {
        loadMoreTriggerIDs = Set(sortedRows.suffix(5).map(\.id))
    }
}
