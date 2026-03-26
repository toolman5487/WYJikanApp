//
//  HeroBannerViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/25.
//

import Foundation
import Combine

@MainActor
final class HeroBannerViewModel: ObservableObject {
    struct BannerItem: Identifiable, Hashable {
        let id: Int
        let imageURL: URL
    }

    @Published private(set) var items: [BannerItem] = []
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private let service: MainHomeServicing
    private var timerCancellable: AnyCancellable?

    init(service: MainHomeServicing = MainHomeService()) {
        self.service = service
    }

    func loadIfNeeded() {
        guard items.isEmpty, !isLoading else { return }
        load()
    }
    
    func setCurrentIndex(_ newValue: Int) {
        currentIndex = newValue
    }

    func load() {
        isLoading = true
        errorMessage = nil

        Task { [weak self] in
            guard let self else { return }

            do {
                let response = try await self.service.fetchHeroBanner()
                let mapped: [BannerItem] = response.data.compactMap { dto in
                    guard let urlString =
                        dto.images?.webp?.largeImageUrl ??
                        dto.images?.jpg?.largeImageUrl ??
                        dto.images?.webp?.imageUrl ??
                        dto.images?.jpg?.imageUrl,
                    let url = URL(string: urlString)
                    else { return nil }

                    return BannerItem(id: dto.malId, imageURL: url)
                }

                await MainActor.run {
                    self.items = mapped
                    self.currentIndex = 0
                    self.isLoading = false
                    self.startAutoScrollIfNeeded()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.items = []
                    self.currentIndex = 0
                    self.isLoading = false
                    self.stopAutoScroll()
                }
            }
        }
    }

    func startAutoScrollIfNeeded() {
        guard items.count > 1 else {
            stopAutoScroll()
            return
        }

        stopAutoScroll()

        timerCancellable = Timer
            .publish(every: 4.0, tolerance: 0.2, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                guard !self.items.isEmpty else { return }

                let next = (self.currentIndex + 1) % self.items.count
                self.currentIndex = next
            }
    }

    func stopAutoScroll() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
}
