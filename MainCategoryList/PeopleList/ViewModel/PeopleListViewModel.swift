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
    enum PaginationState: Equatable {
        case idle
        case loadingInitial
        case loadingMore
        case error(String)
    }

    enum FooterState: Equatable {
        case hidden
        case loadMore
        case loadingMore
    }

    enum ScreenState {
        case loading
        case error(String)
        case empty
        case content(rows: [PeopleListRow], inlineError: String?, footer: FooterState)
    }

    @Published private(set) var rows: [PeopleListRow] = []
    @Published private(set) var hasNextPage = true
    @Published private(set) var paginationState: PaginationState = .idle
    @Published private(set) var selectedSort: PeopleListSort = .popularity

    private let service: MainCategoryListServicing
    private let pageLimit = 12
    private var currentPage = 0
    private var loadTask: Task<Void, Never>?
    private var sourceRows: [PeopleListRow] = []

    init(service: MainCategoryListServicing = MainCategoryListService()) {
        self.service = service
    }

    var screenState: ScreenState {
        switch paginationState {
        case .loadingInitial where rows.isEmpty:
            return .loading
        case .error(let message) where rows.isEmpty:
            return .error(message)
        case .idle, .loadingInitial, .loadingMore, .error:
            if rows.isEmpty {
                return .empty
            }

            let inlineError: String?
            if case .error(let message) = paginationState {
                inlineError = message
            } else {
                inlineError = nil
            }

            let footer: FooterState
            if !hasNextPage {
                footer = .hidden
            } else if paginationState == .loadingMore {
                footer = .loadingMore
            } else {
                footer = .loadMore
            }

            return .content(rows: rows, inlineError: inlineError, footer: footer)
        }
    }

    func loadIfNeeded() {
        guard rows.isEmpty else { return }
        reload()
    }

    func reload() {
        loadTask?.cancel()
        currentPage = 0
        hasNextPage = true
        sourceRows = []
        rows = []
        paginationState = .idle
        loadPage(1)
    }

    func loadMore() {
        guard hasNextPage else { return }
        switch paginationState {
        case .loadingInitial, .loadingMore:
            return
        default:
            break
        }
        loadPage(currentPage + 1)
    }

    func stop() {
        loadTask?.cancel()
        paginationState = .idle
    }

    func selectSort(_ sort: PeopleListSort) {
        guard selectedSort != sort else { return }
        selectedSort = sort
        applySelectedSort()
    }

    private func loadPage(_ page: Int) {
        let isFirstPage = page == 1
        paginationState = isFirstPage ? .loadingInitial : .loadingMore

        loadTask = Task { [weak self] in
            guard let self else { return }

            do {
                let response = try await service.fetchPeople(page: page, limit: pageLimit)
                guard !Task.isCancelled else { return }

                let newRows = response.data.map(PeopleListRow.from)
                currentPage = response.pagination?.currentPage ?? page
                hasNextPage = response.pagination?.hasNextPage ?? !newRows.isEmpty
                sourceRows = isFirstPage ? newRows : sourceRows + newRows
                applySelectedSort()
                paginationState = .idle
            } catch {
                guard !Task.isCancelled else { return }
                paginationState = .error(error.userFacingMessage)
            }
        }
    }

    private func applySelectedSort() {
        rows = sortedRows(from: sourceRows, sort: selectedSort)
    }

    private func sortedRows(from rows: [PeopleListRow], sort: PeopleListSort) -> [PeopleListRow] {
        switch sort {
        case .popularity:
            return rows.sorted { lhs, rhs in
                switch (lhs.favorites, rhs.favorites) {
                case let (left?, right?) where left != right:
                    return left > right
                case (.some, nil):
                    return true
                case (nil, .some):
                    return false
                default:
                    return lhs.sortTitle.localizedStandardCompare(rhs.sortTitle) == .orderedAscending
                }
            }

        case .nameAscending:
            return rows.sorted { lhs, rhs in
                let result = lhs.sortTitle.localizedStandardCompare(rhs.sortTitle)
                if result == .orderedSame {
                    return (lhs.favorites ?? 0) > (rhs.favorites ?? 0)
                }
                return result == .orderedAscending
            }

        case .nameDescending:
            return rows.sorted { lhs, rhs in
                let result = lhs.sortTitle.localizedStandardCompare(rhs.sortTitle)
                if result == .orderedSame {
                    return (lhs.favorites ?? 0) > (rhs.favorites ?? 0)
                }
                return result == .orderedDescending
            }
        }
    }
}
