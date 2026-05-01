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

    var screenState: MainSearchScreenState {
        MainSearchScreenState.resolve(
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

    private enum SearchEvent: Equatable {
        case queryAdjusted
        case kindAdjusted
    }

    private struct SearchIntent: Equatable {
        let trimmedQuery: String
        let kind: MainSearchKind
        let event: SearchEvent
    }

    private enum SearchOutput {
        case reset
        case loading(clearExistingRows: Bool)
        case result(rows: [MainSearchResultRow], error: String?)
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
            .map { [weak self] event -> SearchIntent? in
                guard let self else {
                    return nil
                }
                return SearchIntent(
                    trimmedQuery: Self.trim(self.query),
                    kind: self.kind,
                    event: event
                )
            }
            .compactMap { $0 }
            .map { [weak self] intent -> AnyPublisher<SearchOutput, Never> in
                guard let self else {
                    return Empty().eraseToAnyPublisher()
                }

                if intent.trimmedQuery.isEmpty {
                    return Just(.reset).eraseToAnyPublisher()
                }

                return self.searchPublisher(for: intent)
            }
            .switchToLatest()
            .receive(on: RunLoop.main)
            .sink { [weak self] output in
                guard let self else { return }
                switch output {
                case .reset:
                    self.rows = []
                    self.errorMessage = nil
                    self.isLoading = false
                case .loading(let clearExistingRows):
                    if clearExistingRows {
                        self.rows = []
                    }
                    self.errorMessage = nil
                    self.isLoading = true
                case .result(let rows, let error):
                    if let error {
                        self.rows = []
                        self.errorMessage = error
                        self.isLoading = false
                    } else {
                        self.rows = rows
                        self.errorMessage = nil
                        self.isLoading = false
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Private

    private static func trim(_ string: String) -> String {
        string.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func searchPublisher(for intent: SearchIntent) -> AnyPublisher<SearchOutput, Never> {
        Deferred { [weak self] () -> AnyPublisher<SearchOutput, Never> in
            guard let self else {
                return Empty().eraseToAnyPublisher()
            }

            let subject = PassthroughSubject<SearchOutput, Never>()
            let clearExistingRows = {
                switch intent.event {
                case .queryAdjusted:
                    return false
                case .kindAdjusted:
                    return true
                }
            }()

            let task = Task { @MainActor [weak self] in
                guard let self else {
                    subject.send(completion: .finished)
                    return
                }

                do {
                    let results = try await self.service.search(
                        kind: intent.kind,
                        query: intent.trimmedQuery,
                        limit: Self.searchResultLimit
                    )
                    guard !Task.isCancelled else {
                        subject.send(completion: .finished)
                        return
                    }
                    subject.send(.result(rows: results, error: nil))
                } catch {
                    guard !Task.isCancelled else {
                        subject.send(completion: .finished)
                        return
                    }
                    subject.send(.result(rows: [], error: error.localizedDescription))
                }

                subject.send(completion: .finished)
            }

            return subject
                .prepend(.loading(clearExistingRows: clearExistingRows))
                .handleEvents(receiveCancel: {
                    task.cancel()
                })
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
}
