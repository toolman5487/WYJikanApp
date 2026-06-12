//
//  MainSearchPresentationBuilder.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/2.
//

import Foundation

struct MainSearchPresentationBuilder: Sendable {
    func screenState(
        query: String,
        sortedRows: [MainSearchResultRow]
    ) -> MainSearchScreenState {
        guard !sortedRows.isEmpty else {
            let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedQuery.isEmpty ? .emptyPrompt : .emptyResults(query: query)
        }

        return .content(sortedRows)
    }

    func loadMoreState(
        requestState: MainSearchRequestState,
        hasNextPage: Bool
    ) -> MainSearchLoadMoreState {
        switch requestState {
        case .loadingMore:
            return .loading
        case .loadMoreError(let failure):
            return .error(failure)
        case .idle, .searching:
            return hasNextPage ? .available : .hidden
        }
    }
}
