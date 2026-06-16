//
//  MangaReadingProgressSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/6/11.
//

import SwiftUI

struct MangaReadingProgressSectionView: View {

    // MARK: - Properties

    let item: MyListCollectionItem
    let manga: MangaDetailDTO
    let onIncrement: (MyListCollectionItem) -> Void
    let onDecrement: (MyListCollectionItem) -> Void
    let onEdit: (MyListCollectionItem) -> Void

    // MARK: - Body

    var body: some View {
        AnimeDetailSectionCard("閱讀進度") {
            savedProgressView
        }
    }

    // MARK: - Private Views

    private var savedProgressView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let progress = item.readingProgressFraction(totalChapters: totalChapters) {
                HStack(spacing: 8) {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .tint(ThemeColor.sakura)

                    Text(progress, format: .percent.precision(.fractionLength(0)))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ThemeColor.sakura)
                        .monospacedDigit()
                }
            }

            chapterStepperView(for: item)
        }
        .accessibilityElement(children: .contain)
    }

    private func chapterStepperView(for item: MyListCollectionItem) -> some View {
        HStack(spacing: 8) {
            Button {
                onDecrement(item)
            } label: {
                Image(systemName: "minus")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(ThemeColor.sakura)
                    .frame(width: 44, height: 44)
                    .background(Color(.secondarySystemBackground))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(ThemeColor.sakura.opacity(0.42), lineWidth: 1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled((item.currentChapter ?? 0) == 0)
            .opacity((item.currentChapter ?? 0) == 0 ? 0.42 : 1)

            Button {
                onEdit(item)
            } label: {
                Text(chapterButtonText(for: item))
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .foregroundStyle(ThemeColor.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                onIncrement(item)
            } label: {
                Image(systemName: "plus")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(ThemeColor.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(ThemeColor.sakura)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isAtLastChapter(item))
            .opacity(isAtLastChapter(item) ? 0.42 : 1)
        }
    }

    // MARK: - Private Methods

    private func chapterButtonText(for item: MyListCollectionItem) -> String {
        item.readingProgressSummary(totalChapters: totalChapters)
    }

    private func isAtLastChapter(_ item: MyListCollectionItem) -> Bool {
        guard let totalChapters else { return false }
        return (item.currentChapter ?? 0) >= totalChapters
    }

    private var totalChapters: Int? {
        guard let chapters = manga.chapters, chapters > 0 else { return nil }
        return chapters
    }
}
