//
//  AnimeListViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import Foundation
import Combine

@MainActor
final class AnimeListViewModel: ObservableObject {
    @Published private(set) var randomPick: AnimeListRandomDTO?
    @Published private(set) var isDrawing: Bool = false
    @Published private(set) var drawError: String?

    private let service: MainCategoryListServicing
    private var drawTask: Task<Void, Never>?

    init(service: MainCategoryListServicing = MainCategoryListService()) {
        self.service = service
    }

    func loadRandomIfNeeded() {
        guard randomPick == nil, !isDrawing, drawError == nil else { return }
        drawRandomAnime()
    }

    func drawRandomAnime() {
        guard !isDrawing else { return }
        drawTask?.cancel()
        isDrawing = true
        drawError = nil

        drawTask = Task { [weak self] in
            guard let self else { return }
            do {
                let response = try await self.service.fetchRandomAnime()
                guard !Task.isCancelled else { return }
                self.randomPick = response.data
                self.isDrawing = false
            } catch {
                guard !Task.isCancelled else { return }
                self.drawError = error.localizedDescription
                self.isDrawing = false
            }
        }
    }

    func stop() {
        drawTask?.cancel()
        drawTask = nil
    }
}
