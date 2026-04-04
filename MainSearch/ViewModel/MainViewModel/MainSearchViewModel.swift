//
//  MainSearchViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/2.
//

import Foundation

@MainActor
@Observable
final class MainSearchViewModel {

    // MARK: - Properties

    private static let debounceNanoseconds: UInt64 = 350_000_000
    private static let searchResultLimit = 25

    var query: String = ""
    var kind: MainSearchKind = .anime

    private(set) var rows: [MainSearchResultRow] = []
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?

    let service: MainSearchServicing
    var searchTask: Task<Void, Never>?

    var bodyState: MainSearchBodyState {
        MainSearchBodyState.resolve(
            trimmedQuery: Self.trim(query),
            query: query,
            isLoading: isLoading,
            errorMessage: errorMessage,
            rows: rows
        )
    }

    init(service: MainSearchServicing = MainSearchService()) {
        self.service = service
    }

    // MARK: - Search

    func scheduleSearch() {
        searchTask?.cancel()

        let trimmed = Self.trim(query)
        if trimmed.isEmpty {
            rows = []
            errorMessage = nil
            isLoading = false
            return
        }

        let currentKind = kind

        searchTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: Self.debounceNanoseconds)
            guard let self, !Task.isCancelled else { return }
            self.isLoading = true
            self.errorMessage = nil
            await self.runSearch(query: trimmed, kind: currentKind)
        }
    }

    func runSearch(query: String, kind: MainSearchKind) async {
        do {
            let results = try await service.search(
                kind: kind,
                query: query,
                limit: Self.searchResultLimit
            )
            guard !Task.isCancelled else { return }
            guard Self.trim(self.query) == query, self.kind == kind else {
                self.isLoading = false
                return
            }
            self.rows = results
            self.errorMessage = nil
            self.isLoading = false
        } catch {
            guard !Task.isCancelled else { return }
            guard Self.trim(self.query) == query, self.kind == kind else {
                self.isLoading = false
                return
            }
            self.rows = []
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }

    // MARK: - Private

    private static func trim(_ string: String) -> String {
        string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
