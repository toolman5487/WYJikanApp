//
//  HeroBannerViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/25.
//

import Combine
import Foundation

enum HeroBannerScreenState: Equatable {
    case loading
    case error(String)
    case empty
    case content([BannerItem])

    var items: [BannerItem] {
        switch self {
        case .content(let items):
            return items
        case .loading, .error, .empty:
            return []
        }
    }

    var hasContent: Bool {
        switch self {
        case .content:
            return true
        case .loading, .error, .empty:
            return false
        }
    }
}

@MainActor
final class HeroBannerViewModel: ObservableObject {
    private enum LoadState {
        case idle
        case loading(Task<Void, Never>)

        nonisolated var task: Task<Void, Never>? {
            switch self {
            case .idle:
                return nil
            case .loading(let task):
                return task
            }
        }

        nonisolated var isLoading: Bool {
            switch self {
            case .idle:
                return false
            case .loading:
                return true
            }
        }
    }
    
    let emptyStateMessage: String
    private static let maxBannerItems = 15
    private static let autoScrollNanoseconds: UInt64 = 4_000_000_000

    @Published private(set) var screenState: HeroBannerScreenState = .loading
    @Published private(set) var currentIndex: Int = 0

    private let service: MainHomeServicing
    private var loadState: LoadState = .idle
    private var autoScrollTask: Task<Void, Never>?

    init(
        service: MainHomeServicing = MainHomeService(),
        emptyStateMessage: String = "目前沒有本季焦點作品"
    ) {
        self.service = service
        self.emptyStateMessage = emptyStateMessage
    }

    deinit {
        loadState.task?.cancel()
        autoScrollTask?.cancel()
    }

    func loadIfNeeded() {
        guard items.isEmpty, !loadState.isLoading else { return }
        load()
    }

    func refresh() async {
        if let task = loadState.task {
            await task.value
            return
        }

        let task = startLoad(forceRefresh: true, showsLoadingState: !screenState.hasContent)
        await task.value
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

    func load() {
        guard !loadState.isLoading else { return }
        _ = startLoad(forceRefresh: false, showsLoadingState: true)
    }

    func startAutoScrollIfNeeded() {
        stopAutoScroll()
        guard items.count > 1 else { return }

        autoScrollTask = Task { @MainActor [weak self] in
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

    private func performLoad(forceRefresh: Bool, showsLoadingState: Bool) async {
        let previousState = screenState
        let previousIndex = currentIndex
        stopAutoScroll()
        defer {
            loadState = .idle
        }

        if showsLoadingState {
            screenState = .loading
        }

        do {
            let response = try await service.fetchHeroBanner(forceRefresh: forceRefresh)
            var seenMalIds = Set<Int>()
            let mapped: [BannerItem] = response.data.compactMap { dto in
                guard let urlString =
                    dto.images?.webp?.largeImageUrl ??
                    dto.images?.jpg?.largeImageUrl ??
                    dto.images?.webp?.imageUrl ??
                    dto.images?.jpg?.imageUrl,
                    let url = URL(string: urlString)
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
                screenState = .error(error.userFacingMessage)
                stopAutoScroll()
            }
        }
    }

    private func startLoad(forceRefresh: Bool, showsLoadingState: Bool) -> Task<Void, Never> {
        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.performLoad(forceRefresh: forceRefresh, showsLoadingState: showsLoadingState)
        }
        loadState = .loading(task)
        return task
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
