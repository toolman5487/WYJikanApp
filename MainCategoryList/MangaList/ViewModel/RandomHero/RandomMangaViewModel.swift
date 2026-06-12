//
//  RandomMangaViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/10.
//

import Foundation
import Combine

@MainActor
final class RandomMangaViewModel: ObservableObject {
    enum DrawState {
        case idle
        case loading
        case ready
        case failure(FeatureLoadFailure)
        case cooldown(remainingSeconds: Int)
    }

    private static let drawCooldownSeconds = 10
    private static let minimumDrawLoadingDuration: Duration = .seconds(2)
    private static let persistedRandomPickKey = "manga.random.lastPick"

    @Published private(set) var drawState: DrawState = .idle
    @Published private(set) var randomPick: MangaListRandomDTO?

    var isDrawing: Bool {
        switch drawState {
        case .loading:
            return true
        case .idle, .ready, .failure, .cooldown:
            return false
        }
    }

    var drawFailure: FeatureLoadFailure? {
        switch drawState {
        case .failure(let failure):
            return failure
        case .idle, .loading, .ready, .cooldown:
            return nil
        }
    }

    var cooldownRemainingSeconds: Int {
        switch drawState {
        case .cooldown(let seconds):
            return seconds
        case .idle, .loading, .ready, .failure:
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
        switch drawState {
        case .idle:
            return "開始抽獎"
        case .ready, .failure, .cooldown:
            return randomPick == nil ? "開始抽獎" : "再抽一次"
        case .loading:
            return "抽獎中..."
        }
    }

    private let service: MainCategoryListServicing
    private let drawCooldownTimer: GlobalCooldownTimer
    private let storage: UserDefaults

    private var drawTask: Task<Void, Never>?
    private var cooldownCancellable: AnyCancellable?

    init(
        service: MainCategoryListServicing,
        storage: UserDefaults = .standard
    ) {
        self.service = service
        self.storage = storage
        self.drawCooldownTimer = GlobalCooldownTimer(
            key: "manga.random.draw",
            cooldownSeconds: Self.drawCooldownSeconds
        )

        let persistedPick = restorePersistedRandomPick()
        randomPick = persistedPick
        drawState = persistedPick == nil ? .idle : .ready
        updateCooldownState(seconds: drawCooldownTimer.remainingSeconds)
        cooldownCancellable = drawCooldownTimer.$remainingSeconds
            .sink { [weak self] seconds in
                self?.updateCooldownState(seconds: seconds)
            }

        if persistedPick == nil {
            drawRandomManga(isAutomatic: true)
        }
    }

    func drawRandomManga() {
        drawRandomManga(isAutomatic: false)
    }

    private func drawRandomManga(isAutomatic: Bool) {
        guard !isDrawing else { return }
        guard drawCooldownTimer.canTrigger else { return }

        drawTask?.cancel()
        drawState = .loading
        let drawStartedAt = ContinuousClock().now

        drawTask = Task { [weak self] in
            guard let self else { return }
            do {
                let response = try await self.service.fetchRandomManga()
                guard !Task.isCancelled else { return }
                await self.waitForMinimumLoadingDuration(since: drawStartedAt)
                guard !Task.isCancelled else { return }
                let pickedManga = response.data
                self.persistRandomPick(pickedManga)
                self.randomPick = pickedManga
                self.drawState = .ready
                self.drawCooldownTimer.startCooldown()
                self.updateCooldownState(seconds: self.drawCooldownTimer.remainingSeconds)
            } catch {
                guard !Task.isCancelled else { return }
                await self.waitForMinimumLoadingDuration(since: drawStartedAt)
                guard !Task.isCancelled else { return }
                if isAutomatic, self.randomPick == nil {
                    self.drawState = .idle
                } else {
                    self.drawState = .failure(FeatureLoadFailure(error))
                }
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
                drawState = randomPick == nil ? .idle : .ready
            }
        }
    }

    private func updateCooldownState(seconds: Int) {
        switch seconds {
        case let remaining where remaining > 0:
            drawState = .cooldown(remainingSeconds: remaining)
        default:
            switch drawState {
            case .cooldown:
                drawState = randomPick == nil ? .idle : .ready
            case .idle, .loading, .ready, .failure:
                break
            }
        }
    }

    private func persistRandomPick(_ pick: MangaListRandomDTO) {
        guard let data = try? JSONEncoder().encode(pick) else { return }
        storage.set(data, forKey: Self.persistedRandomPickKey)
    }

    private func restorePersistedRandomPick() -> MangaListRandomDTO? {
        guard let data = storage.data(forKey: Self.persistedRandomPickKey) else { return nil }
        return try? JSONDecoder().decode(MangaListRandomDTO.self, from: data)
    }

    private func waitForMinimumLoadingDuration(since startTime: ContinuousClock.Instant) async {
        let elapsed = startTime.duration(to: ContinuousClock().now)
        let remaining = Self.minimumDrawLoadingDuration - elapsed
        guard remaining > .zero else { return }
        try? await Task.sleep(for: remaining)
    }
}
