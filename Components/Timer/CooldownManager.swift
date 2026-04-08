//
//  CooldownManager.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import Foundation
import Combine

@MainActor
final class CooldownManager {
    static let shared = CooldownManager()
    private static let storagePrefix = "cooldown.nextFireAt."

    private var nextFireAtByKey: [String: Date] = [:]
    private var subjectsByKey: [String: CurrentValueSubject<Int, Never>] = [:]
    private var ticker: AnyCancellable?

    private init() {
        ticker = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.broadcastAll()
            }
    }

    func publisher(for key: String) -> AnyPublisher<Int, Never> {
        let subject = subject(for: key)
        subject.send(remainingSeconds(for: key))
        return subject.eraseToAnyPublisher()
    }

    func canTrigger(for key: String) -> Bool {
        remainingSeconds(for: key) == 0
    }

    func startCooldown(for key: String, cooldownSeconds: Int) {
        let nextFireAt = Date().addingTimeInterval(TimeInterval(cooldownSeconds))
        nextFireAtByKey[key] = nextFireAt
        persist(nextFireAt: nextFireAt, for: key)
        subject(for: key).send(remainingSeconds(for: key))
    }

    func remainingSeconds(for key: String) -> Int {
        guard let next = nextFireAt(for: key) else { return 0 }
        let remaining = Int(ceil(next.timeIntervalSinceNow))
        if remaining <= 0 {
            nextFireAtByKey[key] = nil
            clearPersistedNextFireAt(for: key)
            return 0
        }
        return remaining
    }

    // MARK: - Private

    private func broadcastAll() {
        for key in subjectsByKey.keys {
            subjectsByKey[key]?.send(remainingSeconds(for: key))
        }
    }

    private func subject(for key: String) -> CurrentValueSubject<Int, Never> {
        if let subject = subjectsByKey[key] {
            return subject
        }
        let subject = CurrentValueSubject<Int, Never>(remainingSeconds(for: key))
        subjectsByKey[key] = subject
        return subject
    }

    private func nextFireAt(for key: String) -> Date? {
        if let inMemory = nextFireAtByKey[key] {
            return inMemory
        }
        let storageKey = Self.storagePrefix + key
        guard let ts = UserDefaults.standard.object(forKey: storageKey) as? TimeInterval else {
            return nil
        }
        let restored = Date(timeIntervalSince1970: ts)
        nextFireAtByKey[key] = restored
        return restored
    }

    private func persist(nextFireAt: Date, for key: String) {
        let storageKey = Self.storagePrefix + key
        UserDefaults.standard.set(nextFireAt.timeIntervalSince1970, forKey: storageKey)
    }

    private func clearPersistedNextFireAt(for key: String) {
        let storageKey = Self.storagePrefix + key
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
