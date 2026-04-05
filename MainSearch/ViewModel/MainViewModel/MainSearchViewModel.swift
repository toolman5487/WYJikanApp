//
//  MainSearchViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/2.
//

import Combine
import Foundation

@MainActor
final class MainSearchViewModel: ObservableObject {

    // MARK: - Properties

    private static let debounceInterval: RunLoop.SchedulerTimeType.Stride = .milliseconds(350)
    private static let searchResultLimit = 25

    @Published var query: String = ""
    @Published var kind: MainSearchKind = .anime

    @Published private(set) var rows: [MainSearchResultRow] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private let service: MainSearchServicing
    private var cancellables = Set<AnyCancellable>()
    private var searchSequence = 0

    var bodyState: MainSearchBodyState {
        MainSearchBodyState.resolve(
            trimmedQuery: Self.trim(query),
            query: query,
            isLoading: isLoading,
            errorMessage: errorMessage,
            rows: rows
        )
    }

    init(service: MainSearchServicing = MainSearchService()) {
        self.service = service
        bindSearchPipeline()
    }

    // MARK: - Combine

    private enum SearchEvent {
        case queryAdjusted
        case kindAdjusted
    }

    private enum SearchOutput {
        case reset
        case result(sequence: Int, rows: [MainSearchResultRow], error: String?)
        case abandoned
    }

    private func bindSearchPipeline() {
        let initialQuerySync = Just(SearchEvent.queryAdjusted)

        let queryPath = $query
            .map { Self.trim($0) }
            .removeDuplicates()
            .debounce(for: Self.debounceInterval, scheduler: RunLoop.main)
            .map { _ in SearchEvent.queryAdjusted }

        let kindPath = $kind
            .removeDuplicates()
            .dropFirst()
            .map { _ in SearchEvent.kindAdjusted }

        let triggers = Publishers.Merge(
            Publishers.Merge(initialQuerySync, queryPath),
            kindPath
        )

        triggers
            .receive(on: RunLoop.main)
            .flatMap { [weak self] event -> AnyPublisher<SearchOutput, Never> in
                guard let self else {
                    return Empty().eraseToAnyPublisher()
                }
                let trimmed = Self.trim(self.query)
                let currentKind = self.kind

                if trimmed.isEmpty {
                    self.searchSequence += 1
                    return Just(.reset).eraseToAnyPublisher()
                }

                self.searchSequence += 1
                let sequence = self.searchSequence

                switch event {
                case .kindAdjusted:
                    self.rows = []
                    self.errorMessage = nil
                    self.isLoading = true
                case .queryAdjusted:
                    self.isLoading = true
                    self.errorMessage = nil
                }

                return Deferred { [weak self] in
                    Future<SearchOutput, Never> { promise in
                        Task { @MainActor [weak self] in
                            guard let self else {
                                promise(.success(.abandoned))
                                return
                            }
                            do {
                                let results = try await self.service.search(
                                    kind: currentKind,
                                    query: trimmed,
                                    limit: Self.searchResultLimit
                                )
                                guard self.matchesSearchIntent(trimmedQuery: trimmed, kind: currentKind) else {
                                    promise(.success(.abandoned))
                                    return
                                }
                                promise(.success(.result(sequence: sequence, rows: results, error: nil)))
                            } catch {
                                guard self.matchesSearchIntent(trimmedQuery: trimmed, kind: currentKind) else {
                                    promise(.success(.abandoned))
                                    return
                                }
                                promise(.success(.result(sequence: sequence, rows: [], error: error.localizedDescription)))
                            }
                        }
                    }
                }
                .eraseToAnyPublisher()
            }
            .receive(on: RunLoop.main)
            .sink { [weak self] output in
                guard let self else { return }
                switch output {
                case .reset:
                    self.rows = []
                    self.errorMessage = nil
                    self.isLoading = false
                case .result(let sequence, let rows, let error):
                    guard sequence == self.searchSequence else { return }
                    if let error {
                        self.rows = []
                        self.errorMessage = error
                        self.isLoading = false
                    } else {
                        self.rows = rows
                        self.errorMessage = nil
                        self.isLoading = false
                    }
                case .abandoned:
                    break
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Private

    private static func trim(_ string: String) -> String {
        string.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func matchesSearchIntent(trimmedQuery: String, kind: MainSearchKind) -> Bool {
        Self.trim(query) == trimmedQuery && self.kind == kind
    }
}
