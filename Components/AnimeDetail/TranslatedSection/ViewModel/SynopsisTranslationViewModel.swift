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
        guard let trimmedSynopsis = normalizedSynopsis(synopsis) else {
            state = .failed(emptyFailureMessage)
            return
        }

        translationTask?.cancel()
        state = .translating

        translationTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            let translationState = await translator.translate(trimmedSynopsis, context: context)
            guard !Task.isCancelled else { return }
            state = translationState
        }
    }

    func reset() {
        translationTask?.cancel()
        guard state != .idle else { return }
        state = .idle
    }

    func cancel() {
        translationTask?.cancel()
    }

    private func normalizedSynopsis(_ synopsis: String) -> String? {
        let trimmedSynopsis = synopsis.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedSynopsis != "-", !trimmedSynopsis.isEmpty else { return nil }
        return trimmedSynopsis
    }

}
