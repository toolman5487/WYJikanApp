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

    var query: String = ""
    var kind: MainSearchKind = .anime

    private(set) var rows: [MainSearchResultRow] = []
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?

    private let service: MainSearchServicing
    private var searchTask: Task<Void, Never>?

    private static let debounceNanoseconds: UInt64 = 350_000_000
    private static let resultLimit = 25

    init(service: MainSearchServicing = MainSearchService()) {
        self.service = service
    }

    func scheduleSearch() {
        searchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
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

    private func runSearch(query: String, kind: MainSearchKind) async {
        do {
            let results = try await service.search(kind: kind, query: query, limit: Self.resultLimit)
            guard !Task.isCancelled else { return }
            guard self.query.trimmingCharacters(in: .whitespacesAndNewlines) == query, self.kind == kind else {
                self.isLoading = false
                return
            }
            self.rows = results
            self.errorMessage = nil
            self.isLoading = false
        } catch {
            guard !Task.isCancelled else { return }
            guard self.query.trimmingCharacters(in: .whitespacesAndNewlines) == query, self.kind == kind else {
                self.isLoading = false
                return
            }
            self.rows = []
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
}
