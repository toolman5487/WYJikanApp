//
//  AnimeDetailSectionComponents.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import SwiftUI

struct SynopsisTranslationButton: View {
    let state: SynopsisTranslationState
    var idleTitle: String = "翻譯劇情"
    var translatedTitle: String = "重新翻譯"
    let action: () -> Void

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
        .accessibilityLabel(title)
    }

    private var title: String {
        switch state {
        case .idle, .failed:
            return idleTitle
        case .translating:
            return "翻譯中"
        case .translated:
            return translatedTitle
        }
    }
}

struct TranslatedSynopsisTextView: View {
    let originalText: String
    let translationState: SynopsisTranslationState
    var primaryFont: Font = .body
    var originalFont: Font = .body

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

struct AnimeDetailSectionCard<Content: View>: View {
    let title: String
    private let titleAccessory: AnyView?
    private let content: Content

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

struct AnimeDetailInfoRow: View {
    let title: String
    let value: String
    var subtitle: String?
    var isValueCopyable: Bool

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
        .accessibilityElement(children: .combine)
    }

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
