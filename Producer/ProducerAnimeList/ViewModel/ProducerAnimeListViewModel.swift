//
//  ProducerAnimeListViewModel.swift
//  WYJikanApp
//

import Combine
import Foundation

@MainActor
final class ProducerAnimeListViewModel: ObservableObject {

    // MARK: - Types

    enum ScreenState {
        case loading
        case content([AnimeCategoryItemDTO])
        case empty
        case error(FeatureLoadFailure)
    }

    typealias LoadMoreState = PaginationFooterState

    // MARK: - Published State

    @Published var selectedSort: AnimeCategoryFilter.Sort = .defaultSort
    @Published var selectedFormat: AnimeCategoryFilter.Format = .all
    @Published private(set) var screenState: ScreenState = .loading
    @Published private(set) var loadMoreState: LoadMoreState = .hidden

    // MARK: - Dependencies

    let producerName: String

    private let producerId: Int
    private let service: ProducerAnimeListServicing
    private let requestLifecycleController: RequestScreenLifecycleController
    let parentTab: JikanAPIRequestScope

    // MARK: - Pagination State

    private let pageSize = 24
    private let paginationController = PaginatedListLoadingController<AnimeCategoryItemDTO>()
    private var cancellables: Set<AnyCancellable> = []
    private var filterRequestTask: Task<Void, Never>?

    // MARK: - Init

    init(
        producerId: Int,
        producerName: String,
        service: ProducerAnimeListServicing,
        parentTab: JikanAPIRequestScope,
        requestLifecycleScope: RequestLifecycleScope,
        requestLifecycleController: any RequestLifecycleControlling
    ) {
        self.producerId = producerId
        self.producerName = producerName
        self.service = service
        self.parentTab = parentTab
        self.requestLifecycleController = RequestScreenLifecycleController(
            scope: requestLifecycleScope,
            requestLifecycleController: requestLifecycleController
        )
        bindFilters()
    }

    // MARK: - Public Methods

    func screenDidAppear() async {
        guard await requestLifecycleController.activate() else { return }
        await performInitialLoadIfNeeded()
    }

    func screenDidDisappear() {
        stop()
        requestLifecycleController.deactivate()
    }

    func reload() async {
        await performReload()
    }

    func loadMore() async {
        await performLoadMore()
    }

    func retryLoadMore() async {
        guard case .error = loadMoreState else { return }
        await performLoadMore()
    }

    // MARK: - Filter Binding

    private var currentFilter: AnimeCategoryFilter {
        AnimeCategoryFilter(
            sort: selectedSort,
            format: selectedFormat
        )
    }

    private func bindFilters() {
        Publishers.CombineLatest(
            $selectedSort.removeDuplicates(),
            $selectedFormat.removeDuplicates()
        )
        .dropFirst()
        .sink { [weak self] _, _ in
            guard let self, self.paginationController.hasLoaded else { return }
            self.filterRequestTask?.cancel()
            self.filterRequestTask = Task(priority: .userInitiated) { [weak self] in
                guard let self else { return }
                await self.reload()
            }
        }
        .store(in: &cancellables)
    }

    // MARK: - Loading

    private func performInitialLoadIfNeeded() async {
        await paginationController.loadIfNeeded(
            setLoading: applyLoading,
            fetchPage: fetchPage,
            applyPresentation: applyPresentation,
            applyError: applyInitialLoadError
        )
    }

    private func performReload() async {
        await paginationController.reload(
            showSkeleton: true,
            setLoading: applyLoading,
            fetchPage: fetchPage,
            applyPresentation: applyPresentation,
            applyError: applyInitialLoadError
        )
    }

    private func performLoadMore() async {
        await paginationController.loadMore(
            fetchPage: fetchPage,
            setFooterState: applyFooterState,
            applyPresentation: applyPresentation
        )
    }

    private func fetchPage(_ page: Int) async throws -> PaginatedPage<AnimeCategoryItemDTO> {
        let animePage = try await service.fetchAnimePage(
            producerId: producerId,
            page: page,
            pageSize: pageSize,
            filter: currentFilter
        )
        return PaginatedPage(
            items: animePage.items,
            currentPage: animePage.currentPage,
            hasNextPage: animePage.hasNextPage
        )
    }

    private func applyLoading(footerState: PaginationFooterState) {
        screenState = .loading
        loadMoreState = footerState
    }

    private func applyInitialLoadError(
        _ failure: FeatureLoadFailure,
        footerState: PaginationFooterState
    ) {
        screenState = .error(failure)
        loadMoreState = footerState
    }

    private func applyFooterState(_ footerState: PaginationFooterState) {
        loadMoreState = footerState
    }

    private func applyPresentation(
        items: [AnimeCategoryItemDTO],
        footerState: PaginationFooterState
    ) {
        screenState = items.isEmpty ? .empty : .content(items)
        loadMoreState = items.isEmpty ? .hidden : footerState
    }
}

extension ProducerAnimeListViewModel: PaginatedListLoadControlling {
    var canLoadMore: Bool {
        paginationController.canLoadMore
    }

    var isLoadingMore: Bool {
        loadMoreState == .loading
    }

    func loadIfNeeded() {
        paginationController.run { [weak self] in
            await self?.performInitialLoadIfNeeded()
        }
    }

    func loadMore() {
        paginationController.run { [weak self] in
            await self?.performLoadMore()
        }
    }

    func reload() {
        paginationController.run { [weak self] in
            await self?.performReload()
        }
    }

    func stop() {
        filterRequestTask?.cancel()
        filterRequestTask = nil
        paginationController.stopLoading()
    }
}

extension ProducerAnimeListViewModel: RequestScreenLifecyclePresentable {}
