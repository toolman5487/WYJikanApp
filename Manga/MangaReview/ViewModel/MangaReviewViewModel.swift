//
//  MangaReviewViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/2.
//

import Combine
import Foundation

@MainActor
final class MangaReviewViewModel: ObservableObject {
    enum ScreenState {
        case loading
        case error(String)
        case empty
        case content([MangaReviewEntryDTO])
    }

    enum LoadMoreState: Equatable {
        case hidden
        case available
        case loading
        case error(String)
    }

    @Published private(set) var screenState: ScreenState = .loading
    @Published private(set) var loadMoreState: LoadMoreState = .hidden

    private let malId: Int
    private let service: MangaReviewServicing
    private var loadedPage = 0
    private var isLoading = false
    private var isLoadingMore = false
    private var hasNextPage = false

    init(malId: Int, service: MangaReviewServicing = MangaReviewService()) {
        self.malId = malId
        self.service = service
    }

    var reviews: [MangaReviewEntryDTO] {
        switch screenState {
        case .content(let reviews):
            return reviews
        case .loading, .error, .empty:
            return []
        }
    }

    // MARK: - Load

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        screenState = .loading
        defer { isLoading = false }

        loadedPage = 0
        hasNextPage = false
        loadMoreState = .hidden

        do {
            let response = try await service.fetchReviews(malId: malId, page: 1)
            hasNextPage = response.pagination?.hasNextPage ?? false
            loadedPage = 1
            screenState = response.data.isEmpty ? .empty : .content(response.data)
            loadMoreState = hasNextPage ? .available : .hidden
        } catch is CancellationError {
            return
        } catch {
            screenState = .error(error.localizedDescription)
        }
    }

    func loadMore() async {
        guard hasNextPage, !isLoadingMore, !isLoading, loadedPage > 0 else { return }
        isLoadingMore = true
        loadMoreState = .loading
        defer { isLoadingMore = false }

        let nextPage = loadedPage + 1
        do {
            let response = try await service.fetchReviews(malId: malId, page: nextPage)
            let mergedReviews = reviews + response.data
            hasNextPage = response.pagination?.hasNextPage ?? false
            loadedPage = nextPage
            screenState = mergedReviews.isEmpty ? .empty : .content(mergedReviews)
            loadMoreState = hasNextPage ? .available : .hidden
        } catch is CancellationError {
            return
        } catch {
            loadMoreState = .error("載入更多失敗")
        }
    }
}
