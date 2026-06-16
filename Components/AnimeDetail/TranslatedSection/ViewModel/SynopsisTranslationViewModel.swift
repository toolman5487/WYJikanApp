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
    private var preparationTask: Task<SynopsisTranslationState, Never>?
    private var preparedSynopsis: String?
    private var preparedState: SynopsisTranslationState?

    init(
        context: SynopsisTranslationContext,
        translator: any SynopsisTranslating = SynopsisTranslationService()
    ) {
        self.context = context
        self.translator = translator
    }

    deinit {
        translationTask?.cancel()
        preparationTask?.cancel()
    }

    func prepareTranslation(for synopsis: String) {
        guard let trimmedSynopsis = normalizedSynopsis(synopsis) else { return }
        guard preparedSynopsis != trimmedSynopsis else { return }

        preparationTask?.cancel()
        preparedSynopsis = trimmedSynopsis
        preparedState = nil

        preparationTask = Task(priority: .utility) { [translator, context] in
            await translator.translate(trimmedSynopsis, context: context)
        }
    }

    func requestTranslation(for synopsis: String, emptyFailureMessage: String) {
        guard let trimmedSynopsis = normalizedSynopsis(synopsis) else {
            state = .failed(emptyFailureMessage)
            return
        }

        translationTask?.cancel()

        if let preparedTranslation = translatedPreparedState(for: trimmedSynopsis) {
            state = preparedTranslation
            return
        }

        state = .translating

        if let preparationTask, preparedSynopsis == trimmedSynopsis {
            translationTask = Task(priority: .userInitiated) { [weak self] in
                let translationState = await preparationTask.value
                guard !Task.isCancelled else { return }
                self?.applyPreparedState(translationState, for: trimmedSynopsis)
            }
            return
        }

        preparedSynopsis = trimmedSynopsis
        preparedState = nil
        preparationTask?.cancel()
        preparationTask = nil

        translationTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            let translationState = await translator.translate(trimmedSynopsis, context: context)
            guard !Task.isCancelled else { return }
            applyPreparedState(translationState, for: trimmedSynopsis)
        }
    }

    func reset() {
        translationTask?.cancel()
        preparationTask?.cancel()
        preparedSynopsis = nil
        preparedState = nil
        guard state != .idle else { return }
        state = .idle
    }

    func cancel() {
        translationTask?.cancel()
        preparationTask?.cancel()
    }

    private func normalizedSynopsis(_ synopsis: String) -> String? {
        let trimmedSynopsis = synopsis.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedSynopsis != "-", !trimmedSynopsis.isEmpty else { return nil }
        return trimmedSynopsis
    }

    private func translatedPreparedState(for synopsis: String) -> SynopsisTranslationState? {
        guard preparedSynopsis == synopsis,
              case .translated = preparedState else {
            return nil
        }
        return preparedState
    }

    private func applyPreparedState(_ translationState: SynopsisTranslationState, for synopsis: String) {
        guard preparedSynopsis == synopsis else { return }
        preparedState = translationState
        state = translationState
    }
}
