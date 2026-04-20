//
//  PeopleListViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/19.
//

import Foundation
import Combine

@MainActor
final class PeopleListViewModel: ObservableObject {
    @Published private(set) var rows: [PeopleListRow] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var hasNextPage = true

    private let service: MainCategoryListServicing
    private let pageLimit = 12
    private var currentPage = 0
    private var loadTask: Task<Void, Never>?

    init(service: MainCategoryListServicing = MainCategoryListService()) {
        self.service = service
    }

    func loadIfNeeded() {
        guard rows.isEmpty else { return }
        reload()
    }

    func reload() {
        loadTask?.cancel()
        currentPage = 0
        hasNextPage = true
        rows = []
        errorMessage = nil
        loadPage(1)
    }

    func loadMore() {
        guard hasNextPage, !isLoading, !isLoadingMore else { return }
        loadPage(currentPage + 1)
    }

    func stop() {
        loadTask?.cancel()
        isLoading = false
        isLoadingMore = false
    }

    private func loadPage(_ page: Int) {
        let isFirstPage = page == 1
        isLoading = isFirstPage
        isLoadingMore = !isFirstPage
        errorMessage = nil

        loadTask = Task { [weak self] in
            guard let self else { return }

            do {
                let response = try await service.fetchPeople(page: page, limit: pageLimit)
                guard !Task.isCancelled else { return }

                let newRows = response.data.map(PeopleListRow.from)
                currentPage = response.pagination?.currentPage ?? page
                hasNextPage = response.pagination?.hasNextPage ?? !newRows.isEmpty
                rows = isFirstPage ? newRows : rows + newRows
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = error.localizedDescription
            }

            isLoading = false
            isLoadingMore = false
        }
    }
}
