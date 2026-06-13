//
//  MainSearchSearchPublisherFactory.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/2.
//

import Combine
import Foundation

// MARK: - MainSearchEvent

enum MainSearchEvent: Equatable, Sendable {
    case queryAdjusted
    case kindAdjusted

    var clearsExistingRows: Bool {
        switch self {
        case .queryAdjusted:
            return false
        case .kindAdjusted:
            return true
        }
    }
}

// MARK: - MainSearchIntent

struct MainSearchIntent: Equatable, Sendable {
    let trimmedQuery: String
    let kind: MainSearchKind
    let event: MainSearchEvent
}

// MARK: - MainSearchSearchOutput

enum MainSearchSearchOutput: Sendable {
    case reset
    case loading(clearExistingRows: Bool)
    case result(intent: MainSearchIntent, page: MainSearchPage, error: FeatureLoadFailure?)
}

// MARK: - MainSearchSearchPublisherFactory

@MainActor
struct MainSearchSearchPublisherFactory {

    // MARK: - Properties

    private let service: MainSearchServicing
    private let resultLimit: Int

    // MARK: - Lifecycle

    init(service: MainSearchServicing, resultLimit: Int) {
        self.service = service
        self.resultLimit = resultLimit
    }

    // MARK: - Publishers

    func publisher(for intent: MainSearchIntent) -> AnyPublisher<MainSearchSearchOutput, Never> {
        guard !intent.trimmedQuery.isEmpty else {
            return Just(.reset).eraseToAnyPublisher()
        }

        let service = service
        let resultLimit = resultLimit

        return Deferred {
            let subject = PassthroughSubject<MainSearchSearchOutput, Never>()
            let task = Task { @MainActor in
                do {
                    let page = try await service.searchPage(
                        kind: intent.kind,
                        query: intent.trimmedQuery,
                        page: 1,
                        limit: resultLimit
                    )
                    guard !Task.isCancelled else {
                        subject.send(completion: .finished)
                        return
                    }
                    subject.send(.result(intent: intent, page: page, error: nil))
                } catch {
                    guard !Task.isCancelled else {
                        subject.send(completion: .finished)
                        return
                    }
                    subject.send(
                        .result(
                            intent: intent,
                            page: MainSearchPage(
                                rows: [],
                                currentPage: 1,
                                hasNextPage: false
                            ),
                            error: FeatureLoadFailure(error)
                        )
                    )
                }

                subject.send(completion: .finished)
            }

            return subject
                .prepend(.loading(clearExistingRows: intent.event.clearsExistingRows))
                .handleEvents(receiveCancel: {
                    task.cancel()
                })
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Loading

    func loadPage(
        for intent: MainSearchIntent,
        page: Int
    ) async throws -> MainSearchPage {
        try await service.searchPage(
            kind: intent.kind,
            query: intent.trimmedQuery,
            page: page,
            limit: resultLimit
        )
    }
}
