//
//  AnimeDetailSectionComponents.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import SwiftUI

// MARK: - SynopsisTranslationButton

struct SynopsisTranslationButton: View {

    // MARK: - Properties

    let state: SynopsisTranslationState
    var idleTitle: String = "翻譯劇情"
    var translatedTitle: String = "重新翻譯"
    let action: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if state.isTranslating {
                    ProgressView()
                        .controlSize(.mini)
                } else {
                    Image(systemName: "translate")
                        .font(.footnote.weight(.semibold))
                }

                Text(title)
                    .font(.footnote.weight(.semibold))
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .disabled(state.isTranslating)
    }

    // MARK: - Private

    private var title: String {
        switch state {
        case .idle:
            return idleTitle
        case .failed:
            return idleTitle
        case .translating:
            return "翻譯中"
        case .translated:
            return translatedTitle
        }
    }
}

// MARK: - TranslatedSynopsisTextView

struct TranslatedSynopsisTextView: View {

    // MARK: - Properties

    let originalText: String
    let translationState: SynopsisTranslationState
    var primaryFont: Font = .body
    var originalFont: Font = .body

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            translatedSynopsisView
            originalSynopsisView

            if let failureMessage = translationState.failureMessage {
                Text(failureMessage)
                    .font(.footnote)
                    .foregroundStyle(ThemeColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Translated Synopsis

    @ViewBuilder
    private var translatedSynopsisView: some View {
        switch translationState {
        case let .translated(text):
            Text(text)
                .font(primaryFont)
                .foregroundStyle(ThemeColor.textPrimary.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

        case .idle, .translating, .failed:
            Text(originalText)
                .font(primaryFont)
                .foregroundStyle(ThemeColor.textPrimary.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Original Synopsis

    @ViewBuilder
    private var originalSynopsisView: some View {
        if case .translated = translationState {
            DisclosureGroup("原文") {
                Text(originalText)
                    .font(originalFont)
                    .foregroundStyle(ThemeColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - ReviewTranslationContentView

struct ReviewTranslationContentView: View {

    // MARK: - Properties

    let originalText: String
    let translationState: SynopsisTranslationState
    let onTranslate: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                Spacer(minLength: 8)

                SynopsisTranslationButton(
                    state: translationState,
                    idleTitle: "翻譯評論",
                    translatedTitle: "重新翻譯",
                    action: onTranslate
                )
            }

            TranslatedSynopsisTextView(
                originalText: originalText,
                translationState: translationState
            )
        }
    }
}

// MARK: - SynopsisTranslationSectionView

struct SynopsisTranslationSectionView: View {

    // MARK: - Properties

    let title: String
    let originalText: String
    let translationState: SynopsisTranslationState
    var idleTitle: String = "翻譯劇情"
    var translatedTitle: String = "重新翻譯"
    var primaryFont: Font = .body
    var originalFont: Font = .body
    let onTranslate: () -> Void

    // MARK: - Body

    var body: some View {
        AnimeDetailSectionCard(
            title,
            titleAccessory: {
                SynopsisTranslationButton(
                    state: translationState,
                    idleTitle: idleTitle,
                    translatedTitle: translatedTitle,
                    action: onTranslate
                )
            }
        ) {
            TranslatedSynopsisTextView(
                originalText: originalText,
                translationState: translationState,
                primaryFont: primaryFont,
                originalFont: originalFont
            )
        }
    }
}

// MARK: - AnimeDetailSectionCard

struct AnimeDetailSectionCard<Content: View>: View {

    // MARK: - Properties

    let title: String
    private let titleAccessory: AnyView?
    private let content: Content

    // MARK: - Lifecycle

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.titleAccessory = nil
        self.content = content()
    }

    init<TitleAccessory: View>(
        _ title: String,
        @ViewBuilder titleAccessory: () -> TitleAccessory,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.titleAccessory = AnyView(titleAccessory())
        self.content = content()
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                Text(title)
                    .font(.title3)
                    .foregroundStyle(ThemeColor.sakura)

                if let titleAccessory {
                    Spacer(minLength: 8)
                    titleAccessory
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - AnimeDetailInfoRow

struct AnimeDetailInfoRow: View {

    // MARK: - Properties

    let title: String
    let value: String
    var subtitle: String?
    var isValueCopyable: Bool

    // MARK: - Lifecycle

    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        isValueCopyable: Bool = false
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.isValueCopyable = isValueCopyable
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ThemeColor.textSecondary)
                .frame(width: 72, alignment: .leading)

            Group {
                if let subtitle, !subtitle.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        valueContent
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(ThemeColor.textTertiary)
                    }
                } else {
                    valueContent
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Value Content

    @ViewBuilder
    private var valueContent: some View {
        if isValueCopyable, value != "-" {
            DetailCopyableText(text: value, style: .info)
        } else {
            Text(value)
                .font(.subheadline)
                .foregroundStyle(ThemeColor.textPrimary)
        }
    }
}
