//
//  MangaCategoryDetailViewModel.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/2.
//

import Foundation
import Combine

@MainActor
final class MangaCategoryDetailViewModel: ObservableObject {
    enum ScreenState {
        case loading
        case content(items: [MangaCategoryItemDTO])
        case empty
        case error(FeatureLoadFailure)
    }

    typealias LoadMoreState = PaginationFooterState

    // MARK: - Published State

    @Published var selectedSort: MangaCategoryFilter.Sort = .defaultSort
    @Published var selectedFormat: MangaCategoryFilter.Format = .all
    @Published private(set) var screenState: ScreenState = .loading
    @Published private(set) var loadMoreState: LoadMoreState = .hidden

    // MARK: - Dependencies

    let genre: MangaListGenreDTO

    private let service: MangaCategoryDetailServicing
    private let requestLifecycleController: RequestScreenLifecycleController

    // MARK: - Pagination State

    private let pageSize = 24
    private let paginationController = PaginatedListLoadingController<MangaCategoryItemDTO>()
    private var cancellables: Set<AnyCancellable> = []
    private var filterRequestTask: Task<Void, Never>?

    // MARK: - Init

    init(
        genre: MangaListGenreDTO,
        service: MangaCategoryDetailServicing,
        requestLifecycleScope: RequestLifecycleScope,
        requestLifecycleManager: any RequestLifecycleManaging
    ) {
        self.genre = genre
        self.service = service
        self.requestLifecycleController = RequestScreenLifecycleController(
            scope: requestLifecycleScope,
            requestLifecycleManager: requestLifecycleManager
        )
        bindPresentation()
    }

    // MARK: - Derived State

    var genreTitle: String {
        genre.name ?? "未分類"
    }

    var headerSubtitle: String {
        "\(genreTitle) 類作品集中頁面，會依你選擇的條件重新整理資料，往下完整探索。"
    }

    var loadedCountText: String {
        "已載入 \(paginationController.items.count) 部"
    }

    // MARK: - Public Methods

    func screenDidAppear() async {
        guard await requestLifecycleController.activate() else { return }
        await paginationController.loadIfNeeded(
            setLoading: applyLoading,
            fetchPage: fetchPage,
            applyPresentation: applyPresentation,
            applyError: applyInitialLoadError
        )
    }

    func screenDidDisappear() {
        filterRequestTask?.cancel()
        filterRequestTask = nil
        requestLifecycleController.deactivate()
    }

    func reload() async {
        await fetchFirstPage(showSkeleton: true)
    }

    func loadMore() async {
        await loadMorePage()
    }

    func retryLoadMore() async {
        guard case .error = loadMoreState else { return }
        await loadMorePage()
    }

    func loadMoreIfNeeded(currentItem item: MangaCategoryItemDTO) async {
        guard shouldLoadMore(after: item) else { return }
        await loadMorePage()
    }

    // MARK: - Filter Binding

    private var currentFilter: MangaCategoryFilter {
        MangaCategoryFilter(sort: selectedSort, format: selectedFormat)
    }

    private func bindPresentation() {
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
                await self.fetchFirstPage(showSkeleton: true)
            }
        }
        .store(in: &cancellables)
    }

    // MARK: - Loading

    private func fetchFirstPage(showSkeleton: Bool) async {
        filterRequestTask = nil
        await paginationController.reload(
            showSkeleton: showSkeleton,
            setLoading: applyLoading,
            fetchPage: fetchPage,
            applyPresentation: applyPresentation,
            applyError: applyInitialLoadError
        )
    }

    private func loadMorePage() async {
        await paginationController.loadMore(
            fetchPage: fetchPage,
            setFooterState: applyFooterState,
            applyPresentation: applyPresentation
        )
    }

    private func fetchPage(_ page: Int) async throws -> PaginatedPage<MangaCategoryItemDTO> {
        let categoryPage: MangaCategoryPage
        if page == 1 {
            categoryPage = try await service.fetchInitialPage(
                genreId: genre.id,
                pageSize: pageSize,
                filter: currentFilter
            )
        } else {
            categoryPage = try await service.fetchPage(
                genreId: genre.id,
                page: page,
                pageSize: pageSize,
                filter: currentFilter
            )
        }

        return PaginatedPage(
            items: categoryPage.items,
            currentPage: categoryPage.currentPage,
            hasNextPage: categoryPage.hasNextPage
        )
    }

    private func applyLoading(footerState: PaginationFooterState) {
        screenState = .loading
        loadMoreState = footerState
    }

    private func applyInitialLoadError(_ failure: FeatureLoadFailure, footerState: PaginationFooterState) {
        screenState = .error(failure)
        loadMoreState = footerState
    }

    private func applyFooterState(_ footerState: PaginationFooterState) {
        loadMoreState = footerState
    }

    private func applyPresentation(items: [MangaCategoryItemDTO], footerState: PaginationFooterState) {
        guard !items.isEmpty else {
            screenState = .empty
            loadMoreState = .hidden
            return
        }

        screenState = .content(items: items)
        loadMoreState = footerState
    }

    private func shouldLoadMore(after item: MangaCategoryItemDTO) -> Bool {
        guard case .content(let items) = screenState else { return false }
        return paginationController.shouldLoadMore(after: item, visibleItems: items)
    }
}
