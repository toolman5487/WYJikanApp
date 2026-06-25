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
    enum LoadState: Equatable {
        case idle
        case loadingInitial
        case loadingMore
        case paused
        case error(FeatureLoadFailure)
    }

    enum FooterState: Equatable {
        case hidden
        case loadMore
        case loadingMore
    }

    enum ScreenState {
        case loading
        case error(FeatureLoadFailure)
        case empty
        case content(rows: [PeopleListRow], inlineError: FeatureLoadFailure?, footer: FooterState)
    }

    @Published private(set) var rows: [PeopleListRow] = []
    @Published private(set) var hasNextPage = true
    @Published private(set) var loadState: LoadState = .idle
    @Published private(set) var selectedSort: PeopleListSort = .popularity

    private let service: MainCategoryListServicing
    private let pageLimit = 12
    private var currentPage = 0
    private var loadTask: Task<Void, Never>?
    private var sourceRows: [PeopleListRow] = []

    init(service: MainCategoryListServicing) {
        self.service = service
    }

    var screenState: ScreenState {
        switch loadState {
        case .loadingInitial where rows.isEmpty:
            return .loading
        case .error(let failure) where rows.isEmpty:
            return .error(failure)
        case .idle:
            if rows.isEmpty {
                return currentPage == 0 ? .loading : .empty
            }

            let inlineError: FeatureLoadFailure?
            if case .error(let failure) = loadState {
                inlineError = failure
            } else {
                inlineError = nil
            }

            let footer: FooterState
            if !hasNextPage {
                footer = .hidden
            } else if loadState == .loadingMore {
                footer = .loadingMore
            } else {
                footer = .loadMore
            }

            return .content(rows: rows, inlineError: inlineError, footer: footer)
        case .loadingInitial:
            if rows.isEmpty {
                return .loading
            }

            let inlineError: FeatureLoadFailure?
            if case .error(let failure) = loadState {
                inlineError = failure
            } else {
                inlineError = nil
            }

            let footer: FooterState
            if !hasNextPage {
                footer = .hidden
            } else if loadState == .loadingMore {
                footer = .loadingMore
            } else {
                footer = .loadMore
            }

            return .content(rows: rows, inlineError: inlineError, footer: footer)
        case .loadingMore:
            if rows.isEmpty {
                return .loading
            }

            let inlineError: FeatureLoadFailure?
            if case .error(let failure) = loadState {
                inlineError = failure
            } else {
                inlineError = nil
            }

            let footer: FooterState
            if !hasNextPage {
                footer = .hidden
            } else if loadState == .loadingMore {
                footer = .loadingMore
            } else {
                footer = .loadMore
            }

            return .content(rows: rows, inlineError: inlineError, footer: footer)
        case .paused:
            if rows.isEmpty {
                return .loading
            }

            let inlineError: FeatureLoadFailure?
            if case .error(let failure) = loadState {
                inlineError = failure
            } else {
                inlineError = nil
            }

            let footer: FooterState
            if !hasNextPage {
                footer = .hidden
            } else if loadState == .loadingMore {
                footer = .loadingMore
            } else {
                footer = .loadMore
            }

            return .content(rows: rows, inlineError: inlineError, footer: footer)
        case .error:
            if rows.isEmpty {
                return .empty
            }

            let inlineError: FeatureLoadFailure?
            if case .error(let failure) = loadState {
                inlineError = failure
            } else {
                inlineError = nil
            }

            let footer: FooterState
            if !hasNextPage {
                footer = .hidden
            } else if loadState == .loadingMore {
                footer = .loadingMore
            } else {
                footer = .loadMore
            }

            return .content(rows: rows, inlineError: inlineError, footer: footer)
        }
    }

    func loadIfNeeded() {
        switch loadState {
        case .idle where rows.isEmpty:
            reload()
        case .paused:
            resumeLoading()
        case .idle, .loadingInitial, .loadingMore, .error:
            break
        }
    }

    func reload() {
        loadTask?.cancel()
        currentPage = 0
        hasNextPage = true
        sourceRows = []
        rows = []
        loadState = .idle
        loadPage(1)
    }

    func loadMore() {
        guard hasNextPage else { return }
        switch loadState {
        case .loadingInitial:
            return
        case .loadingMore:
            return
        case .idle, .paused, .error:
            break
        }
        loadPage(currentPage + 1)
    }

    func stop() {
        loadTask?.cancel()
        loadTask = nil

        switch loadState {
        case .loadingInitial, .loadingMore:
            loadState = .paused
        case .idle, .paused, .error:
            break
        }
    }

    func selectSort(_ sort: PeopleListSort) {
        guard selectedSort != sort else { return }
        selectedSort = sort
        applySelectedSort()
    }

    private func resumeLoading() {
        let page = currentPage == 0 ? 1 : currentPage + 1
        loadPage(page)
    }

    private func loadPage(_ page: Int) {
        let isFirstPage = page == 1
        loadState = isFirstPage ? .loadingInitial : .loadingMore

        loadTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            do {
                let response = try await service.fetchPeople(page: page, limit: pageLimit)
                guard !Task.isCancelled else { return }

                let newRows = response.data.map(PeopleListRow.from)
                currentPage = response.pagination?.currentPage ?? page
                hasNextPage = response.pagination?.hasNextPage ?? !newRows.isEmpty
                sourceRows = isFirstPage ? newRows : sourceRows + newRows
                applySelectedSort()
                loadState = .idle
            } catch {
                guard !Task.isCancelled else { return }
                loadState = .error(FeatureLoadFailure(error))
            }
        }
    }

    private func applySelectedSort() {
        rows = sortedRows(from: sourceRows, sort: selectedSort)
    }

    private func sortedRows(from rows: [PeopleListRow], sort: PeopleListSort) -> [PeopleListRow] {
        switch sort {
        case .popularity:
            return rows

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

extension PeopleListViewModel.LoadState {
    var permitsLoadMore: Bool {
        switch self {
        case .loadingMore, .error:
            return false
        case .idle, .loadingInitial, .paused:
            return true
        }
    }
}

extension PeopleListViewModel: PaginatedListLoadControlling {
    var canLoadMore: Bool {
        hasNextPage && loadState.permitsLoadMore
    }

    var isLoadingMore: Bool {
        loadState == .loadingMore
    }
}
