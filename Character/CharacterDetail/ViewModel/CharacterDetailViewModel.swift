//
//  CharacterDetailViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/22.
//

import Combine
import Foundation

@MainActor
final class CharacterDetailViewModel: ObservableObject {

    enum ScreenState {
        case loading
        case loaded(CharacterDetailDTO)
        case error(FeatureLoadFailure)

        var detail: CharacterDetailDTO? {
            switch self {
            case .loaded(let detail):
                return detail
            case .loading, .error:
                return nil
            }
        }
    }

    private enum LoadState {
        case idle
        case loading

        var isLoading: Bool {
            switch self {
            case .idle:
                return false
            case .loading:
                return true
            }
        }
    }

    @Published private(set) var screenState: ScreenState = .loading

    private let malId: Int
    private let service: CharacterDetailServicing
    private var loadState: LoadState = .idle

    init(malId: Int, service: CharacterDetailServicing) {
        self.malId = malId
        self.service = service
    }

    var detail: CharacterDetailDTO? {
        screenState.detail
    }

    func load() async {
        guard detail == nil, !loadState.isLoading else { return }

        loadState = .loading
        screenState = .loading
        defer { loadState = .idle }

        do {
            let response = try await service.fetchCharacterDetail(malId: malId)
            screenState = .loaded(response.data)
        } catch is CancellationError {
            return
        } catch {
            screenState = .error(FeatureLoadFailure(error))
        }
    }
}
