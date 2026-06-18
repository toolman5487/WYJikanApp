//
//  SettingService.swift
//  WYJikanApp
//

import Combine
import Foundation

@MainActor
protocol SettingServicing: AnyObject {
    var searchHistoryCountPublisher: AnyPublisher<Int, Never> { get }

    func searchHistoryCount() -> Int
}

@MainActor
final class SettingService: SettingServicing {

    // MARK: - Dependencies

    private let historyRepository: any MainSearchHistoryRepository

    // MARK: - Lifecycle

    init(historyRepository: any MainSearchHistoryRepository) {
        self.historyRepository = historyRepository
    }

    // MARK: - SettingServicing

    var searchHistoryCountPublisher: AnyPublisher<Int, Never> {
        historyRepository.historyPublisher
            .map(\.count)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func searchHistoryCount() -> Int {
        historyRepository.loadHistory().count
    }
}
