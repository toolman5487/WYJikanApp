//
//  MainSearchViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/2.
//

import Combine
import Foundation

@MainActor
final class MainSearchViewModel: ObservableObject {

    // MARK: - Properties

    private static let debounceInterval: RunLoop.SchedulerTimeType.Stride = .milliseconds(350)
    private static let searchResultLimit = 25

    @Published var query: String = ""
    @Published var kind: MainSearchKind = .anime
    @Published var sortOption: MainSearchSortOption = .default

    @Published private(set) var rows: [MainSearchResultRow] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isLoadingMore: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var loadMoreErrorMessage: String?

    private let service: MainSearchServicing
    private var cancellables = Set<AnyCancellable>()
    private var unsortedRows: [MainSearchResultRow] = []
    private var currentPage = 0
    private var hasNextPage = false
    private var activeIntent: SearchIntent?
    private var loadMoreTask: Task<Void, Never>?

    var screenState: MainSearchScreenState {
        MainSearchScreenState.resolve(
            trimmedQuery: Self.trim(query),
            query: query,
            isLoading: isLoading,
            errorMessage: errorMessage,
            rows: rows
        )
    }

    init(service: MainSearchServicing = MainSearchService()) {
        self.service = service
        bindSearchPipeline()
        bindSortPipeline()
    }

    // MARK: - Combine

    private enum SearchEvent: Equatable {
        case queryAdjusted
        case kindAdjusted
    }

    private struct SearchIntent: Equatable {
        let trimmedQuery: String
        let kind: MainSearchKind
        let event: SearchEvent
    }

    private enum SearchOutput {
        case reset
        case loading(clearExistingRows: Bool)
        case result(page: MainSearchPage, error: String?)
    }

    private func bindSearchPipeline() {
        let initialQuerySync = Just(SearchEvent.queryAdjusted)

        let queryPath = $query
            .map { Self.trim($0) }
            .removeDuplicates()
            .debounce(for: Self.debounceInterval, scheduler: RunLoop.main)
            .map { _ in SearchEvent.queryAdjusted }

        let kindPath = $kind
            .removeDuplicates()
            .dropFirst()
            .map { _ in SearchEvent.kindAdjusted }

        let triggers = Publishers.Merge(
            Publishers.Merge(initialQuerySync, queryPath),
            kindPath
        )

        triggers
            .receive(on: RunLoop.main)
            .map { [weak self] event -> SearchIntent? in
                guard let self else {
                    return nil
                }
                return SearchIntent(
                    trimmedQuery: Self.trim(self.query),
                    kind: self.kind,
                    event: event
                )
            }
            .compactMap { $0 }
            .map { [weak self] intent -> AnyPublisher<SearchOutput, Never> in
                guard let self else {
                    return Empty().eraseToAnyPublisher()
                }

                if intent.trimmedQuery.isEmpty {
                    return Just(.reset).eraseToAnyPublisher()
                }

                return self.searchPublisher(for: intent)
            }
            .switchToLatest()
            .receive(on: RunLoop.main)
            .sink { [weak self] output in
                guard let self else { return }
                switch output {
                case .reset:
                    self.loadMoreTask?.cancel()
                    self.activeIntent = nil
                    self.currentPage = 0
                    self.hasNextPage = false
                    self.unsortedRows = []
                    self.rows = []
                    self.errorMessage = nil
                    self.loadMoreErrorMessage = nil
                    self.isLoading = false
                    self.isLoadingMore = false
                case .loading(let clearExistingRows):
                    self.loadMoreTask?.cancel()
                    if clearExistingRows {
                        self.activeIntent = nil
                        self.currentPage = 0
                        self.hasNextPage = false
                        self.unsortedRows = []
                        self.rows = []
                    }
                    self.errorMessage = nil
                    self.loadMoreErrorMessage = nil
                    self.isLoading = true
                    self.isLoadingMore = false
                case .result(let page, let error):
                    if let error {
                        self.activeIntent = nil
                        self.currentPage = 0
                        self.hasNextPage = false
                        self.unsortedRows = []
                        self.rows = []
                        self.errorMessage = error
                        self.loadMoreErrorMessage = nil
                        self.isLoading = false
                        self.isLoadingMore = false
                    } else {
                        self.activeIntent = SearchIntent(
                            trimmedQuery: Self.trim(self.query),
                            kind: self.kind,
                            event: .queryAdjusted
                        )
                        self.currentPage = page.currentPage
                        self.hasNextPage = page.hasNextPage
                        self.unsortedRows = page.rows
                        self.rows = self.sortedRows(from: page.rows, using: self.sortOption)
                        self.errorMessage = nil
                        self.loadMoreErrorMessage = nil
                        self.isLoading = false
                        self.isLoadingMore = false
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func bindSortPipeline() {
        $kind
            .removeDuplicates()
            .sink { [weak self] kind in
                guard let self else { return }
                let supportedOptions = MainSearchSortOption.supportedOptions(for: kind)
                if !supportedOptions.contains(self.sortOption) {
                    self.sortOption = .default
                }
            }
            .store(in: &cancellables)

        $sortOption
            .removeDuplicates()
            .sink { [weak self] option in
                guard let self else { return }
                self.rows = self.sortedRows(from: self.unsortedRows, using: option)
            }
            .store(in: &cancellables)
    }

    // MARK: - Private

    private static func trim(_ string: String) -> String {
        string.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func loadMoreIfNeeded(currentRow: MainSearchResultRow) {
        guard hasNextPage, !isLoading, !isLoadingMore else { return }
        guard loadMoreErrorMessage == nil else { return }
        guard let currentIndex = rows.firstIndex(where: { $0.id == currentRow.id }) else { return }
        let thresholdIndex = max(rows.count - 5, 0)
        guard currentIndex >= thresholdIndex else { return }
        loadMore()
    }

    func retryLoadMore() {
        guard hasNextPage, !isLoading, !isLoadingMore else { return }
        loadMore()
    }

    private func searchPublisher(for intent: SearchIntent) -> AnyPublisher<SearchOutput, Never> {
        Deferred { [weak self] () -> AnyPublisher<SearchOutput, Never> in
            guard let self else {
                return Empty().eraseToAnyPublisher()
            }

            let subject = PassthroughSubject<SearchOutput, Never>()
            let clearExistingRows = {
                switch intent.event {
                case .queryAdjusted:
                    return false
                case .kindAdjusted:
                    return true
                }
            }()

            let task = Task { @MainActor [weak self] in
                guard let self else {
                    subject.send(completion: .finished)
                    return
                }

                do {
                    let page = try await self.service.searchPage(
                        kind: intent.kind,
                        query: intent.trimmedQuery,
                        page: 1,
                        limit: Self.searchResultLimit
                    )
                    guard !Task.isCancelled else {
                        subject.send(completion: .finished)
                        return
                    }
                    subject.send(.result(page: page, error: nil))
                } catch {
                    guard !Task.isCancelled else {
                        subject.send(completion: .finished)
                        return
                    }
                    subject.send(
                        .result(
                            page: MainSearchPage(rows: [], currentPage: 1, hasNextPage: false),
                            error: error.localizedDescription
                        )
                    )
                }

                subject.send(completion: .finished)
            }

            return subject
                .prepend(.loading(clearExistingRows: clearExistingRows))
                .handleEvents(receiveCancel: {
                    task.cancel()
                })
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }

    private func loadMore() {
        guard let activeIntent else { return }

        isLoadingMore = true
        loadMoreErrorMessage = nil
        loadMoreTask?.cancel()
        let nextPage = currentPage + 1

        loadMoreTask = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                let page = try await self.service.searchPage(
                    kind: activeIntent.kind,
                    query: activeIntent.trimmedQuery,
                    page: nextPage,
                    limit: Self.searchResultLimit
                )
                guard !Task.isCancelled else { return }

                self.currentPage = page.currentPage
                self.hasNextPage = page.hasNextPage
                self.unsortedRows += page.rows
                self.rows = self.sortedRows(from: self.unsortedRows, using: self.sortOption)
                self.isLoadingMore = false
                self.loadMoreErrorMessage = nil
            } catch {
                guard !Task.isCancelled else { return }
                self.isLoadingMore = false
                self.loadMoreErrorMessage = error.localizedDescription
            }
        }
    }

    private func sortedRows(
        from rows: [MainSearchResultRow],
        using option: MainSearchSortOption
    ) -> [MainSearchResultRow] {
        switch option {
        case .default:
            return rows
        case .titleAscending:
            return rows.sorted { lhs, rhs in
                lhs.sortTitle.localizedCompare(rhs.sortTitle) == .orderedAscending
            }
        case .titleDescending:
            return rows.sorted { lhs, rhs in
                lhs.sortTitle.localizedCompare(rhs.sortTitle) == .orderedDescending
            }
        case .newest:
            return rows.sorted { lhs, rhs in
                switch (lhs.year, rhs.year) {
                case let (left?, right?):
                    if left == right {
                        return lhs.sortTitle.localizedCompare(rhs.sortTitle) == .orderedAscending
                    }
                    return left > right
                case (.some, .none):
                    return true
                case (.none, .some):
                    return false
                case (.none, .none):
                    return lhs.sortTitle.localizedCompare(rhs.sortTitle) == .orderedAscending
                }
            }
        case .oldest:
            return rows.sorted { lhs, rhs in
                switch (lhs.year, rhs.year) {
                case let (left?, right?):
                    if left == right {
                        return lhs.sortTitle.localizedCompare(rhs.sortTitle) == .orderedAscending
                    }
                    return left < right
                case (.some, .none):
                    return true
                case (.none, .some):
                    return false
                case (.none, .none):
                    return lhs.sortTitle.localizedCompare(rhs.sortTitle) == .orderedAscending
                }
            }
        case .popularityDescending:
            return rows.sorted { lhs, rhs in
                switch (lhs.popularityScore, rhs.popularityScore) {
                case let (left?, right?):
                    if left == right {
                        return lhs.sortTitle.localizedCompare(rhs.sortTitle) == .orderedAscending
                    }
                    return left > right
                case (.some, .none):
                    return true
                case (.none, .some):
                    return false
                case (.none, .none):
                    return lhs.sortTitle.localizedCompare(rhs.sortTitle) == .orderedAscending
                }
            }
        case .popularityAscending:
            return rows.sorted { lhs, rhs in
                switch (lhs.popularityScore, rhs.popularityScore) {
                case let (left?, right?):
                    if left == right {
                        return lhs.sortTitle.localizedCompare(rhs.sortTitle) == .orderedAscending
                    }
                    return left < right
                case (.some, .none):
                    return true
                case (.none, .some):
                    return false
                case (.none, .none):
                    return lhs.sortTitle.localizedCompare(rhs.sortTitle) == .orderedAscending
                }
            }
        }
    }
}
