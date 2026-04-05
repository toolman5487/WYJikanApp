//
//  HeroBannerViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/25.
//

import Combine
import Foundation

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
        emptyStateMessage: String = "Empty Data"
    ) {
        self.service = service
        self.emptyStateMessage = emptyStateMessage
    }

    func loadIfNeeded() {
        guard items.isEmpty, !isLoading else { return }
        load()
    }

    func setCurrentIndex(_ index: Int) {
        currentIndex = index
    }

    func load() {
        loadTask?.cancel()
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
                    return BannerItem(id: dto.malId, imageURL: url)
                }

                let capped = Array(mapped.prefix(Self.maxBannerItems))
                self.items = capped
                self.currentIndex = 0
                self.isLoading = false
                self.startAutoScrollIfNeeded()
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
}
