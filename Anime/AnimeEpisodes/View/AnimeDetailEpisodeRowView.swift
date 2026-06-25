//
//  AnimeDetailEpisodeRowView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/14.
//

import SwiftUI

struct AnimeDetailEpisodeRowView: View, Equatable {

    // MARK: - Properties

    @Environment(\.openURL) private var openURL
    @StateObject private var synopsisTranslationViewModel = SynopsisTranslationViewModel(
        context: .animeEpisode
    )

    let row: AnimeDetailEpisodeRowPresentation
    let onToggle: () -> Void

    // MARK: - Equatable

    static func == (lhs: AnimeDetailEpisodeRowView, rhs: AnimeDetailEpisodeRowView) -> Bool {
        lhs.row == rhs.row
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: toggleIfNeeded) {
                summaryContent
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!row.canExpand)

            if let detail = row.detail {
                expandedContent(for: detail)
                    .padding(.top, 16)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
        )
        .onChange(of: row.id) { _, _ in
            synopsisTranslationViewModel.reset()
        }
        .onDisappear {
            synopsisTranslationViewModel.cancel()
        }
    }

    // MARK: - Summary

    private var summaryContent: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(row.summary.episodeNumberText)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(ThemeColor.sakura)

                    Text(row.summary.title)
                        .font(.headline)
                        .foregroundStyle(ThemeColor.textPrimary)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 0)
                }

                if let airedText = row.summary.airedText {
                    Text(airedText)
                        .font(.caption)
                        .foregroundStyle(ThemeColor.textSecondary)
                }

                if !row.summary.tagTexts.isEmpty {
                    tagRow(row.summary.tagTexts)
                }

                if let synopsisText = row.summary.synopsisText {
                    Text(synopsisText)
                        .font(.caption)
                        .foregroundStyle(ThemeColor.textPrimary.opacity(0.9))
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if row.canExpand {
                Image(systemName: row.isExpanded ? "chevron.up" : "chevron.down")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(ThemeColor.textTertiary)
            }
        }
    }

    // MARK: - Expanded Content

    @ViewBuilder
    private func expandedContent(for detail: AnimeDetailEpisodeDetailPresentation) -> some View {
        switch detail {
        case .loading(let content):
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("載入詳細資料")
                        .font(.caption)
                        .foregroundStyle(ThemeColor.textSecondary)
                }
                detailContent(content)
            }

        case .content(let content):
            detailContent(content)

        case .error(let failure, let content):
            VStack(alignment: .leading, spacing: 16) {
                ErrorMessageView(state: ErrorMessageView.State(failure: failure))
                detailContent(content)
            }
        }
    }

    private func detailContent(_ content: AnimeDetailEpisodeExpandedPresentation) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if let alternateTitle = content.alternateTitle {
                detailLine(title: "別名", value: alternateTitle)
            }

            ForEach(content.infoItems) { item in
                detailLine(title: item.title, value: item.value)
            }

            if let synopsis = content.synopsisText {
                SynopsisTranslationSectionView(
                    title: "劇情簡介",
                    originalText: synopsis,
                    translationState: synopsisTranslationViewModel.state,
                    primaryFont: .callout,
                    originalFont: .callout,
                    onTranslate: {
                        synopsisTranslationViewModel.requestTranslation(
                            for: synopsis,
                            emptyFailureMessage: "沒有可翻譯的劇情簡介。"
                        )
                    }
                )
                .onChange(of: synopsis) { _, _ in
                    synopsisTranslationViewModel.reset()
                }
            }

            if !content.externalLinks.isEmpty {
                externalLinks(content.externalLinks)
            }
        }
    }

    // MARK: - Detail Lines

    private func detailLine(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(ThemeColor.textSecondary)
                .frame(width: 48, alignment: .leading)

            Text(value)
                .font(.callout)
                .foregroundStyle(ThemeColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Tags

    private func tagRow(_ tags: [String]) -> some View {
        HStack(spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(ThemeColor.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - External Links

    private func externalLinks(_ links: [AnimeDetailEpisodeExternalLink]) -> some View {
        HStack(spacing: 8) {
            ForEach(links) { link in
                externalLinkButton(link)
            }
        }
    }

    private func externalLinkButton(_ link: AnimeDetailEpisodeExternalLink) -> some View {
        Button {
            openURL(link.url)
        } label: {
            Label(link.title, systemImage: link.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(ThemeColor.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .background(ThemeColor.sakura)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
        )
    }

    // MARK: - Actions

    private func toggleIfNeeded() {
        guard row.canExpand else { return }
        onToggle()
    }
}
