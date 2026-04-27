//
//  CharacterListViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/19.
//

import Foundation
import Combine

@MainActor
final class CharacterListViewModel: ObservableObject {
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
        case content(rows: [CharacterListRow], inlineError: String?, footer: FooterState)
    }

    @Published private(set) var rows: [CharacterListRow] = []
    @Published private(set) var hasNextPage = true
    @Published private(set) var paginationState: PaginationState = .idle

    private let service: MainCategoryListServicing
    private let pageLimit = 12
    private var currentPage = 0
    private var loadTask: Task<Void, Never>?

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

    private func loadPage(_ page: Int) {
        let isFirstPage = page == 1
        paginationState = isFirstPage ? .loadingInitial : .loadingMore

        loadTask = Task { [weak self] in
            guard let self else { return }

            do {
                let response = try await service.fetchCharacters(page: page, limit: pageLimit)
                guard !Task.isCancelled else { return }

                let newRows = response.data.map(CharacterListRow.from)
                currentPage = response.pagination?.currentPage ?? page
                hasNextPage = response.pagination?.hasNextPage ?? !newRows.isEmpty
                rows = isFirstPage ? newRows : rows + newRows
                paginationState = .idle
            } catch {
                guard !Task.isCancelled else { return }
                paginationState = .error(error.localizedDescription)
            }
        }
    }
}
