//
//  MainNewsViewModel.swift
//  WYJikanApp
//

import Combine
import Foundation

@MainActor
final class MainNewsViewModel: ObservableObject {
    @Published private(set) var selectedFilter: MainNewsSourceFilter = .all
    @Published private(set) var screenState: MainNewsScreenState = .loading

    private let service: MainNewsServicing
    private let presentationBuilder: MainNewsPresentationBuilder
    private var articles: [MainNewsArticle] = []
    private var updatedAt: Date?
    private var hasLoaded = false
    private var requestGeneration = 0

    init(
        service: MainNewsServicing = MainNewsService(),
        presentationBuilder: MainNewsPresentationBuilder = MainNewsPresentationBuilder()
    ) {
        self.service = service
        self.presentationBuilder = presentationBuilder
    }

    var headerContent: MainNewsHeaderContent {
        presentationBuilder.makeHeaderContent(for: screenState)
    }

    var filterItems: [MainNewsSourceFilter] {
        presentationBuilder.filterItems
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await fetchLatestNews(forceRefresh: false, showLoading: true)
    }

    func reload() async {
        await fetchLatestNews(forceRefresh: true, showLoading: true)
    }

    func selectFilter(_ filter: MainNewsSourceFilter) {
        guard selectedFilter != filter else { return }
        selectedFilter = filter
        guard hasLoaded else { return }
        applyPresentation()
    }

    private func fetchLatestNews(
        forceRefresh: Bool,
        showLoading: Bool
    ) async {
        let generation = advanceRequestGeneration()
        if showLoading {
            screenState = .loading
        }

        do {
            let feed = try await service.fetchLatestNews(forceRefresh: forceRefresh)
            guard isCurrentGeneration(generation) else { return }

            hasLoaded = true
            articles = feed.articles
            updatedAt = feed.updatedAt
            applyPresentation()
        } catch is CancellationError {
            return
        } catch {
            guard isCurrentGeneration(generation) else { return }
            screenState = .error(message: error.localizedDescription)
        }
    }

    private func applyPresentation() {
        guard let content = presentationBuilder.makeContent(
            articles: articles,
            selectedFilter: selectedFilter,
            updatedAt: updatedAt
        ) else {
            screenState = .empty
            return
        }

        screenState = .content(content)
    }

    private func advanceRequestGeneration() -> Int {
        requestGeneration += 1
        return requestGeneration
    }

    private func isCurrentGeneration(_ generation: Int) -> Bool {
        generation == requestGeneration
    }
}
