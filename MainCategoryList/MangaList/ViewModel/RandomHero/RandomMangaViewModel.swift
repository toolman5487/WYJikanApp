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
        case loading(pick: MangaListRandomDTO?)
        case ready(pick: MangaListRandomDTO?)
        case failure(message: String, pick: MangaListRandomDTO?)
        case cooldown(pick: MangaListRandomDTO?, remainingSeconds: Int)
    }

    private static let drawCooldownSeconds = 10
    private static let minimumDrawLoadingNanoseconds: UInt64 = 2_000_000_000
    private static let persistedRandomPickKey = "manga.random.lastPick"

    @Published private(set) var drawState: DrawState = .loading(pick: nil)

    var randomPick: MangaListRandomDTO? {
        switch drawState {
        case .loading(let pick), .ready(let pick), .failure(_, let pick), .cooldown(let pick, _):
            return pick
        }
    }

    var isDrawing: Bool {
        if case .loading = drawState {
            return true
        }
        return false
    }

    var drawError: String? {
        if case .failure(let message, _) = drawState {
            return message
        }
        return nil
    }

    var cooldownRemainingSeconds: Int {
        if case .cooldown(_, let seconds) = drawState {
            return seconds
        }
        return 0
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

    private let service: MainCategoryListServicing
    private let drawCooldownTimer: GlobalCooldownTimer
    private let storage: UserDefaults

    private var drawTask: Task<Void, Never>?
    private var cooldownCancellable: AnyCancellable?

    init(
        service: MainCategoryListServicing = MainCategoryListService(),
        storage: UserDefaults = .standard
    ) {
        self.service = service
        self.storage = storage
        self.drawCooldownTimer = GlobalCooldownTimer(
            key: "manga.random.draw",
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

    func drawRandomManga() {
        guard !isDrawing else { return }
        guard drawCooldownTimer.canTrigger else { return }

        drawTask?.cancel()
        let currentPick = randomPick
        drawState = .loading(pick: currentPick)
        let drawStartedAt = Date()

        drawTask = Task { [weak self] in
            guard let self else { return }
            do {
                let response = try await self.service.fetchRandomManga()
                guard !Task.isCancelled else { return }
                await self.waitForMinimumLoadingDuration(since: drawStartedAt)
                guard !Task.isCancelled else { return }
                let pickedManga = response.data
                self.drawState = .ready(pick: pickedManga)
                self.persistRandomPick(pickedManga)
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
        drawCooldownTimer.stop()
        cooldownCancellable?.cancel()
        cooldownCancellable = nil
    }

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

    private func persistRandomPick(_ pick: MangaListRandomDTO) {
        guard let data = try? JSONEncoder().encode(pick) else { return }
        storage.set(data, forKey: Self.persistedRandomPickKey)
    }

    private func restorePersistedRandomPick() -> MangaListRandomDTO? {
        guard let data = storage.data(forKey: Self.persistedRandomPickKey) else { return nil }
        return try? JSONDecoder().decode(MangaListRandomDTO.self, from: data)
    }

    private func waitForMinimumLoadingDuration(since startTime: Date) async {
        let elapsedNanoseconds = UInt64(max(0, Date().timeIntervalSince(startTime)) * 1_000_000_000)
        guard elapsedNanoseconds < Self.minimumDrawLoadingNanoseconds else { return }
        let remainingNanoseconds = Self.minimumDrawLoadingNanoseconds - elapsedNanoseconds
        try? await Task.sleep(nanoseconds: remainingNanoseconds)
    }
}
