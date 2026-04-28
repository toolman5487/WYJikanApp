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
        case loading
        case ready
        case failure(message: String)
        case cooldown(remainingSeconds: Int)
    }

    // MARK: - Constants

    private static let drawCooldownSeconds = 10
    private static let minimumDrawLoadingDuration: Duration = .seconds(2)
    private static let persistedRandomPickKey = "anime.random.lastPick"

    // MARK: - Published State

    @Published private(set) var drawState: DrawState = .loading
    @Published private(set) var randomPick: AnimeListRandomDTO?

    // MARK: - Computed Properties

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
        case .failure(let message):
            return message
        default:
            return nil
        }
    }

    var cooldownRemainingSeconds: Int {
        switch drawState {
        case .cooldown(let seconds):
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
        randomPick = persistedPick
        drawState = .ready
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
        drawState = .loading
        let drawStartedAt = ContinuousClock().now

        drawTask = Task { [weak self] in
            guard let self else { return }
            do {
                let response = try await self.service.fetchRandomAnime()
                guard !Task.isCancelled else { return }
                await self.waitForMinimumLoadingDuration(since: drawStartedAt)
                guard !Task.isCancelled else { return }
                let pickedAnime = response.data
                self.persistRandomPick(pickedAnime)
                self.randomPick = pickedAnime
                self.drawState = .ready
                self.drawCooldownTimer.startCooldown()
                self.updateCooldownState(seconds: self.drawCooldownTimer.remainingSeconds)
            } catch {
                guard !Task.isCancelled else { return }
                await self.waitForMinimumLoadingDuration(since: drawStartedAt)
                guard !Task.isCancelled else { return }
                self.drawState = .failure(message: error.localizedDescription)
            }
        }
    }

    func stop() {
        drawTask?.cancel()
        drawTask = nil
        if isDrawing {
            let seconds = drawCooldownTimer.remainingSeconds
            if seconds > 0 {
                drawState = .cooldown(remainingSeconds: seconds)
            } else {
                drawState = .ready
            }
        }
    }

    // MARK: - Private Methods

    private func updateCooldownState(seconds: Int) {
        switch seconds {
        case let remaining where remaining > 0:
            drawState = .cooldown(remainingSeconds: remaining)
        default:
            switch drawState {
            case .cooldown:
                drawState = .ready
            case .loading, .ready, .failure:
                break
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
