//
//  GlobalCooldownTimer.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import Foundation
import Combine

@MainActor
final class GlobalCooldownTimer: ObservableObject {
    @Published private(set) var remainingSeconds: Int = 0

    private let key: String
    private let cooldownSeconds: Int
    private let manager: CooldownManager
    private var remainingCancellable: AnyCancellable?

    init(
        key: String,
        cooldownSeconds: Int,
        manager: CooldownManager = .shared
    ) {
        self.key = key
        self.cooldownSeconds = cooldownSeconds
        self.manager = manager
        remainingSeconds = manager.remainingSeconds(for: key)
        remainingCancellable = manager.publisher(for: key)
            .sink { [weak self] seconds in
                self?.remainingSeconds = seconds
            }
    }

    var canTrigger: Bool {
        manager.canTrigger(for: key)
    }

    func startCooldown() {
        manager.startCooldown(for: key, cooldownSeconds: cooldownSeconds)
    }

    func stop() {
        remainingCancellable?.cancel()
        remainingCancellable = nil
    }
}
