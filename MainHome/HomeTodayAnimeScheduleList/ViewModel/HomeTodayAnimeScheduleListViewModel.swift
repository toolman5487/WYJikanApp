//
//  HomeTodayAnimeScheduleListViewModel.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/4.
//

import Combine
import Foundation

@MainActor
final class HomeTodayAnimeScheduleListViewModel: ObservableObject {
    enum ScreenState {
        case loading
        case content(sections: [HomeTodayAnimeTimeSection])
        case empty
        case error(FeatureLoadFailure)
    }

    typealias LoadMoreState = PaginationFooterState

    // MARK: - Published State

    @Published var selectedDay: HomeScheduleDay
    @Published private(set) var screenState: ScreenState = .loading
    @Published private(set) var loadMoreState: LoadMoreState = .hidden

    // MARK: - Dependencies

    private let service: HomeTodayAnimeScheduleListServicing
    private let presentationBuilder: HomeTodayAnimeScheduleListPresentationBuilder

    // MARK: - Pagination State

    private let pageSize = 25
    private let paginationController = PaginatedListLoadingController<HomeTodayAnimeTimelineItem>()
    private var loadMoreTriggerIDs: Set<Int> = []
    private var cancellables: Set<AnyCancellable> = []
    private var dayRequestTask: Task<Void, Never>?

    // MARK: - Init

    init(
        initialDay: HomeScheduleDay = .current(),
        service: HomeTodayAnimeScheduleListServicing,
        presentationBuilder: HomeTodayAnimeScheduleListPresentationBuilder = HomeTodayAnimeScheduleListPresentationBuilder()
    ) {
        self.selectedDay = initialDay
        self.service = service
        self.presentationBuilder = presentationBuilder
        bindSelectedDay()
    }

    // MARK: - Derived State

    var headerTitle: String {
        selectedDay == .current() ? "今日播出" : "\(selectedDay.title)播出"
    }

    var headerSubtitle: String {
        "依播出時間整理本週 TV 動畫，點進作品可查看完整詳細資料。"
    }

    var loadedCountText: String {
        "已載入 \(paginationController.items.count) 部"
    }

    // MARK: - Public Methods

    func loadIfNeeded() async {
        await paginationController.loadIfNeeded(
            setLoading: applyLoading,
            fetchPage: fetchPage,
            applyPresentation: applyPresentation,
            applyError: applyInitialLoadError
        )
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

    func loadMoreIfNeeded(currentItem item: HomeTodayAnimeTimelineItem) async {
        guard shouldLoadMore(after: item) else { return }
        await loadMorePage()
    }

    func updateSelectedDay(_ day: HomeScheduleDay) {
        guard selectedDay != day else { return }
        selectedDay = day
    }

    // MARK: - Binding

    private func bindSelectedDay() {
        $selectedDay
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                self.dayRequestTask?.cancel()
                self.dayRequestTask = Task { [weak self] in
                    guard let self else { return }
                    await self.fetchFirstPage(showSkeleton: true)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Loading

    private func fetchFirstPage(showSkeleton: Bool) async {
        loadMoreTriggerIDs = []
        dayRequestTask = nil
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

    private func fetchPage(_ page: Int) async throws -> PaginatedPage<HomeTodayAnimeTimelineItem> {
        let response = try await service.fetchSchedulePage(
            day: selectedDay,
            page: page,
            limit: pageSize
        )
        return PaginatedPage(
            items: response.data.compactMap(presentationBuilder.timelineItem(from:)),
            currentPage: response.pagination?.currentPage ?? page,
            hasNextPage: response.pagination?.hasNextPage ?? !response.data.isEmpty
        )
    }

    private func applyLoading(footerState: PaginationFooterState) {
        screenState = .loading
        loadMoreState = footerState
    }

    private func applyInitialLoadError(_ failure: FeatureLoadFailure, footerState: PaginationFooterState) {
        screenState = .error(failure)
        loadMoreState = .hidden
    }

    private func applyFooterState(_ footerState: PaginationFooterState) {
        loadMoreState = footerState
    }

    private func applyPresentation(items: [HomeTodayAnimeTimelineItem], footerState: PaginationFooterState) {
        guard !items.isEmpty else {
            screenState = .empty
            loadMoreState = footerState
            return
        }

        screenState = .content(sections: presentationBuilder.groupedSections(from: items))
        loadMoreTriggerIDs = Set(items.suffix(5).map(\.id))
        loadMoreState = footerState
    }

    private func shouldLoadMore(after item: HomeTodayAnimeTimelineItem) -> Bool {
        guard paginationController.canLoadMore else { return false }
        return loadMoreTriggerIDs.contains(item.id)
    }
}
