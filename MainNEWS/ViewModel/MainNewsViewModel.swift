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
    private let requestLifecycleController: RequestScreenLifecycleController
    private var articles: [MainNewsArticle] = []
    private var updatedAt: Date?
    private var hasLoaded = false
    private var requestGeneration = 0

    init(
        service: MainNewsServicing,
        requestLifecycleManager: any RequestLifecycleControlling,
        presentationBuilder: MainNewsPresentationBuilder = MainNewsPresentationBuilder()
    ) {
        self.service = service
        self.presentationBuilder = presentationBuilder
        self.requestLifecycleController = RequestScreenLifecycleController(
            scope: .mainNews,
            requestLifecycleManager: requestLifecycleManager
        )
    }

    var headerContent: MainNewsHeaderContent {
        presentationBuilder.makeHeaderContent(for: screenState)
    }

    var isRefreshing: Bool {
        switch screenState {
        case .refreshing:
            return true
        case .loading:
            return false
        case .content:
            return false
        case .empty:
            return false
        case .error:
            return false
        }
    }

    var filterItems: [MainNewsSourceFilter] {
        presentationBuilder.filterItems
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await fetchLatestNews(forceRefresh: false, showLoading: true)
    }

    func screenDidAppear() async {
        guard await requestLifecycleController.activate() else { return }
        await loadIfNeeded()
    }

    func screenDidDisappear() {
        requestGeneration += 1
        requestLifecycleController.deactivate()
    }

    func reload() async {
        guard !isRefreshing else { return }
        await fetchLatestNews(forceRefresh: true, showLoading: !hasLoaded)
    }

    func selectFilter(_ filter: MainNewsSourceFilter) {
        guard selectedFilter != filter else { return }
        selectedFilter = filter
        guard hasLoaded else { return }
        applyPresentation(isRefreshing: isRefreshing)
    }

    private func fetchLatestNews(
        forceRefresh: Bool,
        showLoading: Bool
    ) async {
        let generation = advanceRequestGeneration()
        let existingContent = makeCurrentContent()
        if showLoading {
            screenState = .loading
        } else if let existingContent {
            screenState = .refreshing(existingContent)
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
            if let existingContent, forceRefresh {
                screenState = .content(existingContent)
            } else {
                screenState = .error(FeatureLoadFailure(error))
            }
        }
    }

    private func applyPresentation(isRefreshing: Bool = false) {
        guard let content = makeCurrentContent() else {
            screenState = .empty
            return
        }

        screenState = isRefreshing ? .refreshing(content) : .content(content)
    }

    private func makeCurrentContent() -> MainNewsContent? {
        presentationBuilder.makeContent(
            articles: articles,
            selectedFilter: selectedFilter,
            updatedAt: updatedAt
        )
    }

    private func advanceRequestGeneration() -> Int {
        requestGeneration += 1
        return requestGeneration
    }

    private func isCurrentGeneration(_ generation: Int) -> Bool {
        generation == requestGeneration
    }
}
