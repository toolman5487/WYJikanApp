//
//  AnimeDetailSynopsisSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import FoundationModels
import SwiftUI

struct AnimeDetailSynopsisSectionView: View {
    private enum TranslationState: Equatable {
        case idle
        case translating
        case translated(String)
        case failed(String)
    }

    let viewModel: AnimeDetailViewModel
    let anime: AnimeDetailDTO

    @State private var translationState: TranslationState = .idle
    
    var body: some View {
        AnimeDetailSectionCard(
            sectionTitle,
            titleAccessory: {
                translationButton
            }
        ) {
            VStack(alignment: .leading, spacing: 16) {
                translatedSynopsisView

                originalSynopsisView

                if case let .failed(message) = translationState {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(ThemeColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let url = viewModel.malWorkPageURL(for: anime) {
                    MALWorkPageOpenButton(url: url)
                }
            }
        }
    }

    @ViewBuilder
    private var translatedSynopsisView: some View {
        switch translationState {
        case let .translated(text):
            Text(text)
                .font(.body)
                .foregroundStyle(ThemeColor.textPrimary.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

        case .idle, .translating, .failed:
            Text(originalSynopsisText)
                .font(.body)
                .foregroundStyle(ThemeColor.textPrimary.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var originalSynopsisView: some View {
        if case .translated = translationState {
            DisclosureGroup("原文") {
                Text(originalSynopsisText)
                    .font(.body)
                    .foregroundStyle(ThemeColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var translationButton: some View {
        Button {
            requestSynopsisTranslation()
        } label: {
            HStack(spacing: 8) {
                if case .translating = translationState {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "translate")
                }

                Text(translationButtonTitle)
            }
        }
        .buttonStyle(.bordered)
        .disabled(isTranslating)
        .accessibilityLabel(translationButtonTitle)
    }

    private var sectionTitle: String {
        "作品簡介"
    }

    private var originalSynopsisText: String {
        viewModel.synopsisDisplayText(for: anime)
    }

    private var isTranslating: Bool {
        if case .translating = translationState {
            return true
        }
        return false
    }

    private var translationButtonTitle: String {
        switch translationState {
        case .idle, .failed:
            return "翻譯劇情"
        case .translating:
            return "翻譯中"
        case .translated:
            return "重新翻譯"
        }
    }

    private func requestSynopsisTranslation() {
        translationState = .translating

        Task {
            translationState = await Self.translateSynopsis(originalSynopsisText)
        }
    }

    private nonisolated static func translateSynopsis(
        _ synopsis: String
    ) async -> TranslationState {
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
                instructions: """
                你是動漫作品簡介翻譯助手。只輸出繁體中文譯文，不要加入解釋、標題、評論或額外內容。
                保留角色名、作品專有名詞與括號中的來源標記原意，語氣自然但不要改寫劇情。
                """
            )
            let prompt = """
            請將以下英文動畫劇情簡介翻譯成繁體中文：

            \(synopsis)
            """
            let response = try await session.respond(
                to: prompt,
                options: GenerationOptions(temperature: 0.1, maximumResponseTokens: 1_200)
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

    private nonisolated static func availabilityMessage(
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
