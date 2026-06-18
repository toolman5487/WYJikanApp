//
//  SettingService.swift
//  WYJikanApp
//

import Foundation

@MainActor
protocol SettingServicing: AnyObject {
    func searchHistoryCount() -> Int
}

@MainActor
final class SettingService: SettingServicing {

    // MARK: - Dependencies

    private let dependencies: AppDependencies

    // MARK: - Lifecycle

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    // MARK: - SettingServicing

    func searchHistoryCount() -> Int {
        dependencies.mainSearchHistoryRepository.loadHistory().count
    }
}
