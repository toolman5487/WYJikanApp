//
//  RandomHeroViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/9.
//

import Foundation
import Combine

@MainActor
final class RandomHeroViewModel: ObservableObject {
    // MARK: - Types

    enum DrawState {
        case loading(pick: AnimeListRandomDTO?)
        case ready(pick: AnimeListRandomDTO?)
        case failure(message: String, pick: AnimeListRandomDTO?)
        case cooldown(pick: AnimeListRandomDTO?, remainingSeconds: Int)
    }

    // MARK: - Constants

    private static let drawCooldownSeconds = 10
    private static let minimumDrawLoadingDuration: Duration = .seconds(2)
    private static let persistedRandomPickKey = "anime.random.lastPick"

    // MARK: - Published State

    @Published private(set) var drawState: DrawState = .loading(pick: nil)

    // MARK: - Computed Properties

    var randomPick: AnimeListRandomDTO? {
        switch drawState {
        case .loading(let pick), .ready(let pick), .failure(_, let pick), .cooldown(let pick, _):
            return pick
        }
    }

    var isDrawing: Bool {
        switch drawState {
        case .loading:
            return true
        default:
            return false
        }
    }

    var drawError: String? {
        switch drawState {
        case .failure(let message, _):
            return message
        default:
            return nil
        }
    }

    var cooldownRemainingSeconds: Int {
        switch drawState {
        case .cooldown(_, let seconds):
            return seconds
        default:
            return 0
        }
    }

    var cooldownDisplayText: String {
        let minutes = cooldownRemainingSeconds / 60
        let seconds = cooldownRemainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var canDraw: Bool {
        !isDrawing && cooldownRemainingSeconds == 0
    }

    var drawButtonTitle: String {
        if isDrawing {
            return "抽獎中..."
        }
        if cooldownRemainingSeconds > 0 {
            return "\(cooldownDisplayText) 後可再抽"
        }
        return randomPick == nil ? "開始抽獎" : "再抽一次"
    }

    // MARK: - Dependencies

    private let service: MainCategoryListServicing
    private let drawCooldownTimer: GlobalCooldownTimer
    private let storage: UserDefaults

    // MARK: - Private Properties

    private var drawTask: Task<Void, Never>?
    private var cooldownCancellable: AnyCancellable?

    // MARK: - Lifecycle

    init(
        service: MainCategoryListServicing = MainCategoryListService(),
        storage: UserDefaults = .standard
    ) {
        self.service = service
        self.storage = storage
        self.drawCooldownTimer = GlobalCooldownTimer(
            key: "anime.random.draw",
            cooldownSeconds: Self.drawCooldownSeconds
        )
        let persistedPick = restorePersistedRandomPick()
        drawState = .ready(pick: persistedPick)
        updateCooldownState(seconds: drawCooldownTimer.remainingSeconds)
        cooldownCancellable = drawCooldownTimer.$remainingSeconds
            .sink { [weak self] seconds in
                self?.updateCooldownState(seconds: seconds)
            }
    }

    // MARK: - Public Methods

    func drawRandomAnime() {
        guard !isDrawing else { return }
        guard drawCooldownTimer.canTrigger else { return }
        drawTask?.cancel()
        let currentPick = randomPick
        drawState = .loading(pick: currentPick)
        let drawStartedAt = ContinuousClock().now

        drawTask = Task { [weak self] in
            guard let self else { return }
            do {
                let response = try await self.service.fetchRandomAnime()
                guard !Task.isCancelled else { return }
                await self.waitForMinimumLoadingDuration(since: drawStartedAt)
                guard !Task.isCancelled else { return }
                let pickedAnime = response.data
                self.drawState = .ready(pick: pickedAnime)
                self.persistRandomPick(pickedAnime)
                self.drawCooldownTimer.startCooldown()
                self.updateCooldownState(seconds: self.drawCooldownTimer.remainingSeconds)
            } catch {
                guard !Task.isCancelled else { return }
                await self.waitForMinimumLoadingDuration(since: drawStartedAt)
                guard !Task.isCancelled else { return }
                self.drawState = .failure(
                    message: error.localizedDescription,
                    pick: currentPick
                )
            }
        }
    }

    func stop() {
        drawTask?.cancel()
        drawTask = nil
        if isDrawing {
            let pick = randomPick
            let seconds = drawCooldownTimer.remainingSeconds
            if seconds > 0 {
                drawState = .cooldown(pick: pick, remainingSeconds: seconds)
            } else {
                drawState = .ready(pick: pick)
            }
        }
    }

    // MARK: - Private Methods

    private func updateCooldownState(seconds: Int) {
        let pick = randomPick
        switch seconds {
        case let remaining where remaining > 0:
            drawState = .cooldown(pick: pick, remainingSeconds: remaining)
        default:
            switch drawState {
            case .loading(let currentPick):
                drawState = .loading(pick: currentPick)
            case .ready(let currentPick):
                drawState = .ready(pick: currentPick)
            case .failure(let message, let currentPick):
                drawState = .failure(message: message, pick: currentPick)
            case .cooldown(let currentPick, _):
                drawState = .ready(pick: currentPick)
            }
        }
    }

    private func persistRandomPick(_ pick: AnimeListRandomDTO) {
        guard let data = try? JSONEncoder().encode(pick) else { return }
        storage.set(data, forKey: Self.persistedRandomPickKey)
    }

    private func restorePersistedRandomPick() -> AnimeListRandomDTO? {
        guard let data = storage.data(forKey: Self.persistedRandomPickKey) else { return nil }
        return try? JSONDecoder().decode(AnimeListRandomDTO.self, from: data)
    }

    private func waitForMinimumLoadingDuration(since startTime: ContinuousClock.Instant) async {
        let elapsed = startTime.duration(to: ContinuousClock().now)
        let remaining = Self.minimumDrawLoadingDuration - elapsed
        guard remaining > .zero else { return }
        try? await Task.sleep(for: remaining)
    }
}
