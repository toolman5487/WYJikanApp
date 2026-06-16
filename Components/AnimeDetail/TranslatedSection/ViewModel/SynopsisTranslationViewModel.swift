//
//  SynopsisTranslationViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import Combine
import Foundation

@MainActor
final class SynopsisTranslationViewModel: ObservableObject {
    @Published private(set) var state: SynopsisTranslationState = .idle

    private let context: SynopsisTranslationContext
    private let translator: any SynopsisTranslating
    private var translationTask: Task<Void, Never>?

    init(
        context: SynopsisTranslationContext,
        translator: any SynopsisTranslating = SynopsisTranslationService()
    ) {
        self.context = context
        self.translator = translator
    }

    deinit {
        translationTask?.cancel()
    }

    func requestTranslation(for synopsis: String, emptyFailureMessage: String) {
        let trimmedSynopsis = synopsis.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedSynopsis != "-", !trimmedSynopsis.isEmpty else {
            state = .failed(emptyFailureMessage)
            return
        }

        translationTask?.cancel()
        state = .translating

        translationTask = Task { [weak self] in
            guard let self else { return }
            let translationState = await translator.translate(trimmedSynopsis, context: context)
            guard !Task.isCancelled else { return }
            state = translationState
        }
    }

    func reset() {
        guard state != .idle else { return }
        translationTask?.cancel()
        state = .idle
    }

    func cancel() {
        translationTask?.cancel()
    }
}
