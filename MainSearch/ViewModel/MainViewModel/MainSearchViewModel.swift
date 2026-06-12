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

    @Published private(set) var screenState: MainSearchScreenState = .emptyPrompt
    @Published private(set) var loadMoreState: MainSearchLoadMoreState = .hidden

    private let searchPublisherFactory: MainSearchSearchPublisherFactory
    private let sorter: MainSearchResultSorter
    private let presentationBuilder: MainSearchPresentationBuilder

    private var cancellables = Set<AnyCancellable>()
    private var pagination = MainSearchPaginationState()
    private var loadMoreTask: Task<Void, Never>?

    init(
        service: MainSearchServicing,
        initialKind: MainSearchKind = .anime,
        initialQuery: String = "",
        initialSortOption: MainSearchSortOption = .default,
        sorter: MainSearchResultSorter = MainSearchResultSorter(),
        presentationBuilder: MainSearchPresentationBuilder = MainSearchPresentationBuilder()
    ) {
        self.searchPublisherFactory = MainSearchSearchPublisherFactory(
            service: service,
            resultLimit: Self.searchResultLimit
        )
        self.sorter = sorter
        self.presentationBuilder = presentationBuilder
        self.query = initialQuery
        self.kind = initialKind
        if MainSearchSortOption.supportedOptions(for: initialKind).contains(initialSortOption) {
            self.sortOption = initialSortOption
        }
        bindSearchPipeline()
        bindSortPipeline()
    }

    // MARK: - Public

    func loadMoreIfNeeded(currentRow: MainSearchResultRow) {
        guard pagination.shouldLoadMore(currentRow: currentRow) else { return }
        if case .error = loadMoreState { return }
        loadMore()
    }

    func retryLoadMore() {
        guard pagination.hasNextPage, pagination.canStartLoadMore else { return }
        loadMore()
    }

    var canLoadMoreFromEndBounce: Bool {
        loadMoreState == .available
    }

    func loadMoreFromEndBounce() {
        guard canLoadMoreFromEndBounce else { return }
        loadMore()
    }
}

// MARK: - Combine

private extension MainSearchViewModel {
    func bindSearchPipeline() {
        let initialQuerySync = Just(MainSearchEvent.queryAdjusted)

        let queryPath = $query
            .map { Self.trim($0) }
            .removeDuplicates()
            .debounce(for: Self.debounceInterval, scheduler: RunLoop.main)
            .map { _ in MainSearchEvent.queryAdjusted }

        let kindPath = $kind
            .removeDuplicates()
            .dropFirst()
            .map { _ in MainSearchEvent.kindAdjusted }

        let triggers = Publishers.Merge(
            Publishers.Merge(initialQuerySync, queryPath),
            kindPath
        )

        triggers
            .receive(on: RunLoop.main)
            .map { [weak self] event -> MainSearchIntent? in
                guard let self else {
                    return nil
                }
                return MainSearchIntent(
                    trimmedQuery: Self.trim(self.query),
                    kind: self.kind,
                    event: event
                )
            }
            .compactMap { $0 }
            .map { [weak self] intent -> AnyPublisher<MainSearchSearchOutput, Never> in
                guard let self else {
                    return Empty().eraseToAnyPublisher()
                }
                return self.searchPublisherFactory.publisher(for: intent)
            }
            .switchToLatest()
            .receive(on: RunLoop.main)
            .sink { [weak self] output in
                guard let self else { return }
                switch output {
                case .reset:
                    self.resetSearchState()
                case .loading(let clearExistingRows):
                    self.startSearching(clearExistingRows: clearExistingRows)
                case .result(let intent, let page, let error):
                    self.finishSearch(intent: intent, page: page, error: error)
                }
            }
            .store(in: &cancellables)
    }

    func bindSortPipeline() {
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
                self.applySortedResults(using: option)
            }
            .store(in: &cancellables)
    }
}

// MARK: - Search

private extension MainSearchViewModel {
    static func trim(_ string: String) -> String {
        string.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func resetSearchState() {
        loadMoreTask?.cancel()
        pagination.reset()
        screenState = .emptyPrompt
        loadMoreState = .hidden
    }

    func startSearching(clearExistingRows: Bool) {
        loadMoreTask?.cancel()
        pagination.startSearching(clearExistingRows: clearExistingRows)
        loadMoreState = .hidden
        if clearExistingRows || pagination.unsortedRows.isEmpty {
            screenState = .loading
        }
    }

    func finishSearch(
        intent: MainSearchIntent,
        page: MainSearchPage,
        error: String?
    ) {
        guard let error else {
            pagination.finishSearch(intent: intent, page: page)
            applySortedResults()
            return
        }

        pagination.failSearch()
        screenState = .error(error)
        loadMoreState = .hidden
    }
}

// MARK: - Pagination

private extension MainSearchViewModel {
    func loadMore() {
        guard let activeIntent = pagination.activeIntent else { return }

        pagination.startLoadingMore()
        loadMoreState = .loading
        loadMoreTask?.cancel()
        let nextPage = pagination.nextPage

        loadMoreTask = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                let page = try await self.searchPublisherFactory.loadPage(
                    for: activeIntent,
                    page: nextPage
                )
                guard !Task.isCancelled else { return }

                self.pagination.finishLoadMore(page: page)
                self.applySortedResults()
            } catch {
                guard !Task.isCancelled else { return }
                self.pagination.failLoadMore(message: error.userFacingMessage)
                self.loadMoreState = self.presentationBuilder.loadMoreState(
                    requestState: self.pagination.requestState,
                    hasNextPage: self.pagination.hasNextPage
                )
            }
        }
    }
}

// MARK: - Presentation

private extension MainSearchViewModel {
    func applySortedResults(using option: MainSearchSortOption? = nil) {
        let sortedRows = sorter.sortedRows(
            from: pagination.unsortedRows,
            using: option ?? sortOption
        )
        pagination.updateLoadMoreTriggers(from: sortedRows)

        screenState = presentationBuilder.screenState(
            query: query,
            sortedRows: sortedRows
        )

        guard !sortedRows.isEmpty else {
            loadMoreState = .hidden
            return
        }

        loadMoreState = presentationBuilder.loadMoreState(
            requestState: pagination.requestState,
            hasNextPage: pagination.hasNextPage
        )
    }
}
