//
//  MainSearchHistoryRepository.swift
//  WYJikanApp
//

import Foundation

// MARK: - MainSearchHistoryRepository

protocol MainSearchHistoryRepository {
    func loadHistory() -> [MainSearchHistoryItem]
    func recordSearch(query: String, kind: MainSearchKind) -> [MainSearchHistoryItem]
    func removeHistoryItem(id: MainSearchHistoryItem.ID) -> [MainSearchHistoryItem]
    func clearHistory() -> [MainSearchHistoryItem]
}

// MARK: - UserDefaultsMainSearchHistoryRepository

struct UserDefaultsMainSearchHistoryRepository: MainSearchHistoryRepository {

    // MARK: - Properties

    private static let storageKey = "mainSearch.history"
    private static let maximumHistoryCount = 20

    private let userDefaults: UserDefaults
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder

    // MARK: - Lifecycle

    init(
        userDefaults: UserDefaults = .standard,
        jsonEncoder: JSONEncoder = JSONEncoder(),
        jsonDecoder: JSONDecoder = JSONDecoder()
    ) {
        self.userDefaults = userDefaults
        self.jsonEncoder = jsonEncoder
        self.jsonDecoder = jsonDecoder
    }

    // MARK: - MainSearchHistoryRepository

    func loadHistory() -> [MainSearchHistoryItem] {
        guard let data = userDefaults.data(forKey: Self.storageKey) else {
            return []
        }

        do {
            return try jsonDecoder.decode([MainSearchHistoryItem].self, from: data)
        } catch {
            userDefaults.removeObject(forKey: Self.storageKey)
            return []
        }
    }

    func recordSearch(query: String, kind: MainSearchKind) -> [MainSearchHistoryItem] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else {
            return loadHistory()
        }

        var history = loadHistory().filter {
            $0.kind != kind || $0.query.caseInsensitiveCompare(normalizedQuery) != .orderedSame
        }
        history.insert(
            MainSearchHistoryItem(query: normalizedQuery, kind: kind),
            at: 0
        )

        if history.count > Self.maximumHistoryCount {
            history = Array(history.prefix(Self.maximumHistoryCount))
        }

        persist(history)
        return history
    }

    func removeHistoryItem(id: MainSearchHistoryItem.ID) -> [MainSearchHistoryItem] {
        let history = loadHistory().filter { $0.id != id }
        persist(history)
        return history
    }

    func clearHistory() -> [MainSearchHistoryItem] {
        userDefaults.removeObject(forKey: Self.storageKey)
        return []
    }

    // MARK: - Private Methods

    private func persist(_ history: [MainSearchHistoryItem]) {
        do {
            let data = try jsonEncoder.encode(history)
            userDefaults.set(data, forKey: Self.storageKey)
        } catch {
            userDefaults.removeObject(forKey: Self.storageKey)
        }
    }
}
