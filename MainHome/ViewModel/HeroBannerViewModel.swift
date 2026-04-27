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
    case content
}

@MainActor
final class HeroBannerViewModel: ObservableObject {
    
    let emptyStateMessage: String
    private static let maxBannerItems = 15
    private static let autoScrollNanoseconds: UInt64 = 4_000_000_000

    @Published private(set) var items: [BannerItem] = []
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let service: MainHomeServicing
    private var loadTask: Task<Void, Never>?
    private var autoScrollTask: Task<Void, Never>?

    init(
        service: MainHomeServicing = MainHomeService(),
        emptyStateMessage: String = "目前沒有本季焦點作品"
    ) {
        self.service = service
        self.emptyStateMessage = emptyStateMessage
    }

    deinit {
        loadTask?.cancel()
        autoScrollTask?.cancel()
    }

    func loadIfNeeded() {
        guard items.isEmpty, !isLoading else { return }
        load()
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

    var screenState: HeroBannerScreenState {
        if isLoading {
            return .loading
        }
        if items.isEmpty {
            if let errorMessage,
               errorMessage != emptyStateMessage {
                return .error(errorMessage)
            }
            return .empty
        }
        return .content
    }

    func load() {
        loadTask?.cancel()
        stopAutoScroll()
        isLoading = true
        errorMessage = nil

        loadTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let response = try await self.service.fetchHeroBanner()
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
                self.items = capped
                self.currentIndex = 0
                self.isLoading = false
                self.errorMessage = capped.isEmpty ? self.emptyStateMessage : nil
                self.startAutoScrollIfNeeded()
            } catch is CancellationError {
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.items = []
                self.currentIndex = 0
                self.isLoading = false
                self.stopAutoScroll()
            }
        }
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

    private static func displayTitle(japanese: String?, english: String?, fallback: String?) -> String {
        if let japanese, !japanese.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return japanese
        }
        if let english, !english.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return english
        }
        if let fallback, !fallback.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return fallback
        }
        return "未命名作品"
    }
}
