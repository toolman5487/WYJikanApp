//
//  AnimeReviewViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

import Combine
import Foundation

@MainActor
final class AnimeReviewViewModel: ObservableObject {
    enum ScreenState {
        case loading
        case error(FeatureLoadFailure)
        case empty
        case content([AnimeReviewEntryDTO])

        var reviews: [AnimeReviewEntryDTO] {
            switch self {
            case .content(let reviews):
                return reviews
            case .loading:
                return []
            case .error:
                return []
            case .empty:
                return []
            }
        }
    }

    typealias LoadMoreState = PaginationFooterState

    private enum LoadingPhase {
        case idle
        case initial
        case loadingMore

        var isIdle: Bool {
            switch self {
            case .idle:
                return true
            case .initial:
                return false
            case .loadingMore:
                return false
            }
        }
    }

    @Published private(set) var screenState: ScreenState = .loading
    @Published private(set) var loadMoreState: LoadMoreState = .hidden

    private let malId: Int
    private let service: AnimeReviewServicing
    private let requestLifecycleController: RequestScreenLifecycleController
    private var loadedPage = 0
    private var loadingPhase: LoadingPhase = .idle
    private var hasNextPage = false

    init(
        malId: Int,
        service: AnimeReviewServicing,
        requestLifecycleScope: RequestLifecycleScope,
        requestLifecycleManager: any RequestLifecycleManaging
    ) {
        self.malId = malId
        self.service = service
        self.requestLifecycleController = RequestScreenLifecycleController(
            scope: requestLifecycleScope,
            requestLifecycleManager: requestLifecycleManager
        )
    }

    var reviews: [AnimeReviewEntryDTO] {
        screenState.reviews
    }

    // MARK: - Load

    func screenDidAppear() async {
        guard await requestLifecycleController.activate() else { return }
        guard loadedPage == 0 else { return }
        await load()
    }

    func screenDidDisappear() {
        requestLifecycleController.deactivate()
    }

    func load() async {
        guard loadingPhase.isIdle else { return }
        loadingPhase = .initial
        screenState = .loading
        defer { loadingPhase = .idle }

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
            screenState = reviews.isEmpty ? .loading : .content(reviews)
            return
        } catch {
            screenState = .error(FeatureLoadFailure(error))
        }
    }

    func loadMore() async {
        guard hasNextPage, loadingPhase.isIdle, loadedPage > 0 else { return }
        loadingPhase = .loadingMore
        loadMoreState = .loading
        defer { loadingPhase = .idle }

        let nextPage = loadedPage + 1
        do {
            let response = try await service.fetchReviews(malId: malId, page: nextPage)
            let mergedReviews = reviews + response.data
            hasNextPage = response.pagination?.hasNextPage ?? false
            loadedPage = nextPage
            screenState = mergedReviews.isEmpty ? .empty : .content(mergedReviews)
            loadMoreState = hasNextPage ? .available : .hidden
        } catch is CancellationError {
            loadMoreState = hasNextPage ? .available : .hidden
            return
        } catch {
            loadMoreState = .error(FeatureLoadFailure.loadMore())
        }
    }
}
