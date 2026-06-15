//
//  HeroBannerViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/25.
//

import Combine
import Foundation

typealias HeroBannerScreenState = LoadableContentState<[BannerItem]>

// MARK: - HeroBannerViewModel

@MainActor
final class HeroBannerViewModel: ObservableObject {

    // MARK: - Properties

    let emptyStateMessage: String
    private static let maxBannerItems = 15
    private static let autoScrollNanoseconds: UInt64 = 4_000_000_000

    @Published private(set) var screenState: HeroBannerScreenState = .loading
    @Published private(set) var currentIndex: Int = 0

    private let service: MainHomeServicing
    private let sectionLoader = HomeFeedSectionLoader()
    private var autoScrollTask: Task<Void, Never>?

    // MARK: - Lifecycle

    init(
        service: MainHomeServicing,
        emptyStateMessage: String = "目前沒有本季焦點作品"
    ) {
        self.service = service
        self.emptyStateMessage = emptyStateMessage
    }

    deinit {
        sectionLoader.cancel()
        autoScrollTask?.cancel()
    }

    // MARK: - Derived State

    var currentItem: BannerItem? {
        guard items.indices.contains(currentIndex) else { return nil }
        return items[currentIndex]
    }

    var pageLabel: String {
        guard !items.isEmpty else { return "" }
        return "\(currentIndex + 1) / \(items.count)"
    }

    var items: [BannerItem] {
        screenState.items
    }

    // MARK: - Public Methods

    func loadIfNeeded(priority: TaskPriority = .userInitiated) {
        sectionLoader.loadIfNeeded(isContentEmpty: items.isEmpty) {
            load(priority: priority)
        }
    }

    func refresh() async {
        await sectionLoader.refresh(hasContent: screenState.hasContent) { [weak self] forceRefresh, showsLoadingState in
            await self?.performLoad(forceRefresh: forceRefresh, showsLoadingState: showsLoadingState)
        }
    }

    func setCurrentIndex(_ index: Int) {
        guard items.indices.contains(index) else { return }
        currentIndex = index
        startAutoScrollIfNeeded()
    }

    func retry() {
        load()
    }

    func resumeAutoScrollIfNeeded() {
        startAutoScrollIfNeeded()
    }

    func load(priority: TaskPriority = .userInitiated) {
        sectionLoader.load(priority: priority) { [weak self] forceRefresh, showsLoadingState in
            await self?.performLoad(forceRefresh: forceRefresh, showsLoadingState: showsLoadingState)
        }
    }

    func startAutoScrollIfNeeded() {
        stopAutoScroll()
        guard items.count > 1 else { return }

        autoScrollTask = Task(priority: .low) { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: Self.autoScrollNanoseconds)
                guard let self, !Task.isCancelled else { return }
                let count = self.items.count
                guard count > 1 else { return }
                self.currentIndex = (self.currentIndex + 1) % count
            }
        }
    }

    func stopAutoScroll() {
        autoScrollTask?.cancel()
        autoScrollTask = nil
    }

    // MARK: - Private Methods

    private func performLoad(forceRefresh: Bool, showsLoadingState: Bool) async {
        let previousState = screenState
        let previousIndex = currentIndex
        stopAutoScroll()
        defer {
            sectionLoader.markIdle()
        }

        if showsLoadingState {
            screenState = .loading
        }

        do {
            let response = try await service.fetchHeroBanner(forceRefresh: forceRefresh)
            var seenMalIds = Set<Int>()
            let mapped: [BannerItem] = response.data.compactMap { dto in
                guard let url = JikanImageURLResolver.url(from: dto.images, tier: .full)
                else { return nil }

                guard seenMalIds.insert(dto.malId).inserted else { return nil }
                return BannerItem(
                    id: dto.malId,
                    title: Self.displayTitle(
                        japanese: dto.titleJapanese,
                        english: dto.titleEnglish,
                        fallback: dto.title
                    ),
                    type: dto.type,
                    score: dto.score,
                    imageURL: url
                )
            }

            let capped = Array(mapped.prefix(Self.maxBannerItems))
            currentIndex = 0
            screenState = capped.isEmpty ? .empty : .content(capped)
            startAutoScrollIfNeeded()
        } catch is CancellationError {
            return
        } catch {
            if forceRefresh, case .content(let items) = previousState {
                currentIndex = max(0, min(previousIndex, items.count - 1))
                screenState = previousState
                startAutoScrollIfNeeded()
            } else {
                currentIndex = 0
                screenState = .error(FeatureLoadFailure(error))
                stopAutoScroll()
            }
        }
    }

    private static func displayTitle(japanese: String?, english: String?, fallback: String?) -> String {
        switch [
            japanese?.trimmingCharacters(in: .whitespacesAndNewlines),
            english?.trimmingCharacters(in: .whitespacesAndNewlines),
            fallback?.trimmingCharacters(in: .whitespacesAndNewlines)
        ].compactMap({ $0 }).first(where: { !$0.isEmpty }) {
        case .some(let title):
            return title
        case .none:
            return "未命名作品"
        }
    }
}
