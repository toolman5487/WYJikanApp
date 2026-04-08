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
    private static let drawCooldownSeconds = 180

    @Published private(set) var randomPick: AnimeListRandomDTO?
    @Published private(set) var isDrawing: Bool = false
    @Published private(set) var drawError: String?
    @Published private(set) var cooldownRemainingSeconds: Int = 0

    var cooldownDisplayText: String {
        let minutes = cooldownRemainingSeconds / 60
        let seconds = cooldownRemainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private let service: MainCategoryListServicing
    private let drawCooldownTimer: GlobalCooldownTimer
    private var drawTask: Task<Void, Never>?
    private var cooldownCancellable: AnyCancellable?

    init(service: MainCategoryListServicing = MainCategoryListService()) {
        self.service = service
        self.drawCooldownTimer = GlobalCooldownTimer(
            key: "anime.random.draw",
            cooldownSeconds: Self.drawCooldownSeconds
        )
        cooldownRemainingSeconds = drawCooldownTimer.remainingSeconds
        cooldownCancellable = drawCooldownTimer.$remainingSeconds
            .sink { [weak self] seconds in
                self?.cooldownRemainingSeconds = seconds
            }
    }

    func drawRandomAnime() {
        guard !isDrawing else { return }
        guard drawCooldownTimer.canTrigger else { return }
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
                self.drawCooldownTimer.startCooldown()
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
