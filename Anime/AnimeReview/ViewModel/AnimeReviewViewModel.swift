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
        case error(String)
        case empty
        case content([AnimeReviewEntryDTO])

        var reviews: [AnimeReviewEntryDTO] {
            switch self {
            case .content(let reviews):
                return reviews
            case .loading, .error, .empty:
                return []
            }
        }
    }

    enum LoadMoreState: Equatable {
        case hidden
        case available
        case loading
        case error(String)
    }

    private enum LoadingPhase {
        case idle
        case initial
        case loadingMore

        var isIdle: Bool {
            switch self {
            case .idle:
                return true
            case .initial, .loadingMore:
                return false
            }
        }
    }

    @Published private(set) var screenState: ScreenState = .loading
    @Published private(set) var loadMoreState: LoadMoreState = .hidden

    private let malId: Int
    private let service: AnimeReviewServicing
    private var loadedPage = 0
    private var loadingPhase: LoadingPhase = .idle
    private var hasNextPage = false

    init(malId: Int, service: AnimeReviewServicing) {
        self.malId = malId
        self.service = service
    }

    var reviews: [AnimeReviewEntryDTO] {
        screenState.reviews
    }

    // MARK: - Load

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
            return
        } catch {
            screenState = .error(error.userFacingMessage)
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
            return
        } catch {
            loadMoreState = .error("載入更多失敗")
        }
    }
}
