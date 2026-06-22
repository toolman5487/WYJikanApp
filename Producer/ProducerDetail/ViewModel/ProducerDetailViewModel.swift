//
//  ProducerDetailViewModel.swift
//  WYJikanApp
//

import Combine
import Foundation

@MainActor
final class ProducerDetailViewModel: ObservableObject {

    // MARK: - Types

    enum ScreenState {
        case loading
        case loaded(ProducerDetailDTO)
        case error(FeatureLoadFailure)

        var detail: ProducerDetailDTO? {
            switch self {
            case .loaded(let detail):
                return detail
            case .loading, .error:
                return nil
            }
        }
    }

    enum RelatedAnimeState {
        case loading
        case content([AnimeCategoryItemDTO])
        case empty
        case error(FeatureLoadFailure)
    }

    private enum LoadState {
        case idle
        case loading

        var isLoading: Bool {
            self == .loading
        }
    }

    // MARK: - Properties

    @Published private(set) var screenState: ScreenState = .loading
    @Published private(set) var relatedAnimeState: RelatedAnimeState = .loading

    private let malId: Int
    private let service: ProducerDetailServicing
    private var loadState: LoadState = .idle
    private var isLoadingRelatedAnime = false

    // MARK: - Lifecycle

    init(malId: Int, service: ProducerDetailServicing) {
        self.malId = malId
        self.service = service
    }

    var detail: ProducerDetailDTO? {
        screenState.detail
    }

    // MARK: - Public Methods

    func load() async {
        guard detail == nil, !loadState.isLoading else { return }
        await fetchDetail()
    }

    func reload() async {
        guard !loadState.isLoading else { return }
        await fetchDetail()
    }

    func retryRelatedAnime() async {
        guard !isLoadingRelatedAnime else { return }
        await fetchRelatedAnime()
    }

    // MARK: - Private Methods

    private func fetchDetail() async {
        loadState = .loading
        screenState = .loading
        defer { loadState = .idle }

        do {
            let response = try await service.fetchProducerDetail(malId: malId)
            screenState = .loaded(response.data)
            await fetchRelatedAnime()
        } catch is CancellationError {
            return
        } catch {
            screenState = .error(FeatureLoadFailure(error))
        }
    }

    private func fetchRelatedAnime() async {
        guard !isLoadingRelatedAnime else { return }

        isLoadingRelatedAnime = true
        relatedAnimeState = .loading
        defer { isLoadingRelatedAnime = false }

        do {
            let page = try await service.fetchRelatedAnimePreview(
                producerId: malId,
                limit: 6
            )
            relatedAnimeState = page.items.isEmpty
                ? .empty
                : .content(page.items)
        } catch is CancellationError {
            return
        } catch {
            relatedAnimeState = .error(FeatureLoadFailure(error))
        }
    }
}
