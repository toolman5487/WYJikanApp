//
//  SynopsisTranslationService.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import Foundation
import FoundationModels

nonisolated protocol SynopsisTranslating: Sendable {
    func translate(
        _ synopsis: String,
        context: SynopsisTranslationContext
    ) async -> SynopsisTranslationState
}

nonisolated struct SynopsisTranslationService: SynopsisTranslating {
    func translate(
        _ synopsis: String,
        context: SynopsisTranslationContext
    ) async -> SynopsisTranslationState {
        let model = SystemLanguageModel.default

        switch model.availability {
        case .available:
            break

        case let .unavailable(reason):
            return .failed(availabilityMessage(for: reason))
        }

        do {
            let session = LanguageModelSession(
                model: model,
                instructions: context.instructions
            )
            let prompt = """
            \(context.promptTitle)

            \(synopsis)
            """
            let response = try await session.respond(
                to: prompt,
                options: GenerationOptions(
                    temperature: 0.1,
                    maximumResponseTokens: context.maximumResponseTokens
                )
            )
            let translatedText = response.content.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !translatedText.isEmpty else {
                return .failed("本地 AI 沒有產生可顯示內容。")
            }

            return .translated(translatedText)
        } catch is CancellationError {
            return .idle
        } catch {
            return .failed("本地 AI 翻譯暫時無法使用。")
        }
    }

    private func availabilityMessage(
        for reason: SystemLanguageModel.Availability.UnavailableReason
    ) -> String {
        switch reason {
        case .deviceNotEligible:
            return "此裝置不支援本地 AI 翻譯。"
        case .appleIntelligenceNotEnabled:
            return "請先在系統設定開啟 Apple Intelligence，才能使用本地 AI 翻譯。"
        case .modelNotReady:
            return "本地 AI 模型尚未準備完成，稍後再試。"
        @unknown default:
            return "此裝置目前無法使用本地 AI 翻譯。"
        }
    }
}
