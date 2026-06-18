//
//  MainSearchHistoryRepository.swift
//  WYJikanApp
//

import Combine
import Foundation

// MARK: - MainSearchHistoryRepository

@MainActor
protocol MainSearchHistoryRepository: AnyObject {
    var historyPublisher: AnyPublisher<[MainSearchHistoryItem], Never> { get }

    func loadHistory() -> [MainSearchHistoryItem]
    func recordSearch(query: String, kind: MainSearchKind) -> [MainSearchHistoryItem]
    func removeHistoryItem(id: MainSearchHistoryItem.ID) -> [MainSearchHistoryItem]
    func clearHistory() -> [MainSearchHistoryItem]
}

// MARK: - UserDefaultsMainSearchHistoryRepository

@MainActor
final class UserDefaultsMainSearchHistoryRepository: MainSearchHistoryRepository {

    // MARK: - Properties

    private static let storageKey = "mainSearch.history"
    private static let maximumHistoryCount = 20

    private let userDefaults: UserDefaults
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder
    private let historySubject: CurrentValueSubject<[MainSearchHistoryItem], Never>

    // MARK: - Lifecycle

    init(
        userDefaults: UserDefaults = .standard,
        jsonEncoder: JSONEncoder = JSONEncoder(),
        jsonDecoder: JSONDecoder = JSONDecoder()
    ) {
        self.userDefaults = userDefaults
        self.jsonEncoder = jsonEncoder
        self.jsonDecoder = jsonDecoder
        self.historySubject = CurrentValueSubject(
            Self.loadHistory(
                userDefaults: userDefaults,
                jsonDecoder: jsonDecoder
            )
        )
    }

    // MARK: - MainSearchHistoryRepository

    var historyPublisher: AnyPublisher<[MainSearchHistoryItem], Never> {
        historySubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func loadHistory() -> [MainSearchHistoryItem] {
        historySubject.value
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
        historySubject.send([])
        return []
    }

    // MARK: - Private Methods

    private static func loadHistory(
        userDefaults: UserDefaults,
        jsonDecoder: JSONDecoder
    ) -> [MainSearchHistoryItem] {
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

    private func persist(_ history: [MainSearchHistoryItem]) {
        do {
            let data = try jsonEncoder.encode(history)
            userDefaults.set(data, forKey: Self.storageKey)
            historySubject.send(history)
        } catch {
            userDefaults.removeObject(forKey: Self.storageKey)
            historySubject.send([])
        }
    }
}
