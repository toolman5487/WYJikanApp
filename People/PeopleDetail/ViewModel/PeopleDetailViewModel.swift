//
//  PeopleDetailViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/23.
//

import Combine
import Foundation

@MainActor
final class PeopleDetailViewModel: ObservableObject {

    enum ScreenState {
        case loading
        case loaded(PeopleDetailDTO)
        case error(FeatureLoadFailure)

        var detail: PeopleDetailDTO? {
            switch self {
            case .loaded(let detail):
                return detail
            case .loading:
                return nil
            case .error:
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
    private let service: PeopleDetailServicing
    private let requestLifecycleController: RequestScreenLifecycleController
    let parentTab: JikanAPIRequestScope
    private var loadState: LoadState = .idle

    init(
        malId: Int,
        service: PeopleDetailServicing,
        parentTab: JikanAPIRequestScope,
        requestLifecycleScope: RequestLifecycleScope,
        requestLifecycleController: any RequestLifecycleControlling
    ) {
        self.malId = malId
        self.service = service
        self.parentTab = parentTab
        self.requestLifecycleController = RequestScreenLifecycleController(
            scope: requestLifecycleScope,
            requestLifecycleController: requestLifecycleController
        )
    }

    var detail: PeopleDetailDTO? {
        screenState.detail
    }

    func screenDidAppear() async {
        guard await requestLifecycleController.activate() else { return }
        await load()
    }

    func screenDidDisappear() {
        requestLifecycleController.deactivate()
    }

    private func load() async {
        guard detail == nil, !loadState.isLoading else { return }

        loadState = .loading
        screenState = .loading
        defer { loadState = .idle }

        do {
            let response = try await service.fetchPeopleDetail(malId: malId)
            screenState = .loaded(response.data)
        } catch is CancellationError {
            return
        } catch {
            screenState = .error(FeatureLoadFailure(error))
        }
    }
}

extension PeopleDetailViewModel: RequestScreenLifecyclePresentable {}
