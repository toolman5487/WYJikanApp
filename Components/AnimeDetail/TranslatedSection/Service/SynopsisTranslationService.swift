//
//  SynopsisTranslationService.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import Foundation
import FoundationModels
import OSLog

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
        } catch let error as LanguageModelSession.GenerationError {
            let failure = generationFailure(for: error)
            logFailure(failure, error: error)
            return .failed(failure.userMessage)
        } catch {
            let failure = runtimeFailure(for: error)
            logFailure(failure, error: error)
            return .failed(failure.userMessage)
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

    private func generationFailure(
        for error: LanguageModelSession.GenerationError
    ) -> SynopsisTranslationFailure {
        switch error {
        case .guardrailViolation:
            return .guardrailViolation
        case .rateLimited:
            return .modelBusy
        case .concurrentRequests:
            return .modelBusy
        case .assetsUnavailable:
            return .modelNotReady
        case .exceededContextWindowSize:
            return .contentTooLong
        case .unsupportedLanguageOrLocale:
            return .unsupportedLanguage
        case .refusal:
            return .guardrailViolation
        case .decodingFailure:
            return .generationFailed
        case .unsupportedGuide:
            return .generationFailed
        @unknown default:
            return .generationFailed
        }
    }

    private func runtimeFailure(for error: Error) -> SynopsisTranslationFailure {
        isANEFailure(error) ? .aneInferenceFailed : .generationFailed
    }

    private func isANEFailure(_ error: Error) -> Bool {
        var errors: [NSError] = [error as NSError]
        var visitedErrors: Set<ObjectIdentifier> = []

        while let currentError = errors.popLast() {
            let identifier = ObjectIdentifier(currentError)
            guard visitedErrors.insert(identifier).inserted else { continue }

            let signature = [
                currentError.domain,
                currentError.localizedDescription,
                currentError.localizedFailureReason ?? ""
            ]
                .joined(separator: " ")
                .lowercased()

            if signature.contains("com.apple.appleneuralengine")
                || signature.contains("ane inference")
                || signature.contains("program inference error")
                || signature.contains("e5runner") {
                return true
            }

            if let underlyingError = currentError.userInfo[NSUnderlyingErrorKey] as? NSError {
                errors.append(underlyingError)
            }
        }

        return false
    }

    private func logFailure(
        _ failure: SynopsisTranslationFailure,
        error: Error
    ) {
        let nsError = error as NSError
        AppLogger.domain.error(
            """
            Local AI translation failed: category=\(failure.logCategory, privacy: .public) \
            domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public)
            """
        )
    }
}

// MARK: - SynopsisTranslationFailure

nonisolated private enum SynopsisTranslationFailure {
    case guardrailViolation
    case aneInferenceFailed
    case modelBusy
    case modelNotReady
    case contentTooLong
    case unsupportedLanguage
    case generationFailed

    var userMessage: String {
        switch self {
        case .guardrailViolation:
            return "這段內容觸發 Apple Intelligence 的安全規則，因此無法使用本地 AI 翻譯。"
        case .aneInferenceFailed:
            return "裝置的本地 AI 引擎暫時無法完成翻譯，請稍後再試。"
        case .modelBusy:
            return "本地 AI 目前忙碌或請求過於頻繁，請稍後再試。"
        case .modelNotReady:
            return "本地 AI 模型尚未準備完成，請稍後再試。"
        case .contentTooLong:
            return "這段內容過長，超出本地 AI 可處理的範圍。"
        case .unsupportedLanguage:
            return "本地 AI 目前不支援這段內容的語言或地區設定。"
        case .generationFailed:
            return "本地 AI 翻譯暫時無法完成，請稍後再試。"
        }
    }

    var logCategory: String {
        switch self {
        case .guardrailViolation:
            return "guardrailViolation"
        case .aneInferenceFailed:
            return "aneInferenceFailed"
        case .modelBusy:
            return "modelBusy"
        case .modelNotReady:
            return "modelNotReady"
        case .contentTooLong:
            return "contentTooLong"
        case .unsupportedLanguage:
            return "unsupportedLanguage"
        case .generationFailed:
            return "generationFailed"
        }
    }
}
