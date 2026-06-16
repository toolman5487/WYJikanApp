//
//  AnimeDetailSynopsisSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import SwiftUI

struct AnimeDetailSynopsisSectionView: View {
    @ObservedObject var viewModel: AnimeDetailViewModel
    let anime: AnimeDetailDTO

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

                if case let .failed(message) = viewModel.synopsisTranslationState {
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
        switch viewModel.synopsisTranslationState {
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
        if case .translated = viewModel.synopsisTranslationState {
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
            viewModel.requestSynopsisTranslation(for: anime)
        } label: {
            HStack(spacing: 4) {
                if viewModel.isTranslatingSynopsis {
                    ProgressView()
                        .controlSize(.mini)
                } else {
                    Image(systemName: "translate")
                        .font(.footnote.weight(.semibold))
                }

                Text(translationButtonTitle)
                    .font(.footnote.weight(.semibold))
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .disabled(viewModel.isTranslatingSynopsis)
        .accessibilityLabel(viewModel.synopsisTranslationButtonTitle)
    }

    private var sectionTitle: String {
        "作品簡介"
    }

    private var originalSynopsisText: String {
        viewModel.synopsisDisplayText(for: anime)
    }

    private var translationButtonTitle: String {
        viewModel.synopsisTranslationButtonTitle
    }
}
