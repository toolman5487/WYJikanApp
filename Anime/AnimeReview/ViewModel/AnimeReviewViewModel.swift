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
        case content
    }

    @Published private(set) var reviews: [AnimeReviewEntryDTO] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasNextPage = false
    @Published private(set) var errorMessage: String?

    private let malId: Int
    private let service: AnimeReviewServicing
    private var loadedPage = 0

    init(malId: Int, service: AnimeReviewServicing = AnimeReviewService()) {
        self.malId = malId
        self.service = service
    }

    var screenState: ScreenState {
        if let errorMessage, !errorMessage.isEmpty {
            return .error(errorMessage)
        }
        if isLoading && reviews.isEmpty {
            return .loading
        }
        if reviews.isEmpty {
            return .empty
        }
        return .content
    }

    // MARK: - Load

    func load() async {
        guard !isLoading else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        loadedPage = 0
        reviews = []
        hasNextPage = false

        do {
            let response = try await service.fetchReviews(malId: malId, page: 1)
            reviews = response.data
            hasNextPage = response.pagination?.hasNextPage ?? false
            loadedPage = 1
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
            reviews = []
        }
    }

    func loadMore() async {
        guard hasNextPage, !isLoadingMore, !isLoading, loadedPage > 0 else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        let nextPage = loadedPage + 1
        do {
            let response = try await service.fetchReviews(malId: malId, page: nextPage)
            reviews.append(contentsOf: response.data)
            hasNextPage = response.pagination?.hasNextPage ?? false
            loadedPage = nextPage
        } catch is CancellationError {
            return
        } catch {
            return
        }
    }
}
