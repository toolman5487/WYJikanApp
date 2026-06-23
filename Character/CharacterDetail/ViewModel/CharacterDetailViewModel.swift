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
    let synopsisTranslationViewModel: SynopsisTranslationViewModel

    private let malId: Int
    private let service: CharacterDetailServicing
    private let requestLifecycleController: RequestScreenLifecycleController
    private var loadState: LoadState = .idle

    init(
        malId: Int,
        service: CharacterDetailServicing,
        requestLifecycleScope: RequestLifecycleScope,
        requestLifecycleManager: any RequestLifecycleControlling
    ) {
        self.malId = malId
        self.service = service
        self.requestLifecycleController = RequestScreenLifecycleController(
            scope: requestLifecycleScope,
            requestLifecycleManager: requestLifecycleManager
        )
        self.synopsisTranslationViewModel = SynopsisTranslationViewModel(context: .characterProfile)
    }

    var detail: CharacterDetailDTO? {
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
            let response = try await service.fetchCharacterDetail(malId: malId)
            screenState = .loaded(response.data)
            resetSynopsisTranslation()
        } catch is CancellationError {
            return
        } catch {
            screenState = .error(FeatureLoadFailure(error))
        }
    }

    // MARK: - Synopsis Translation

    func requestSynopsisTranslation(for character: CharacterDetailDTO) {
        synopsisTranslationViewModel.requestTranslation(
            for: aboutText(for: character) ?? "",
            emptyFailureMessage: "沒有可翻譯的角色介紹。"
        )
    }

    private func resetSynopsisTranslation() {
        synopsisTranslationViewModel.reset()
    }
}
