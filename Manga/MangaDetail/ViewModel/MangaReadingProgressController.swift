//
//  MangaReadingProgressController.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/14.
//

import Foundation

struct MangaReadingProgressUpdate {
    let status: MangaReadingStatus
    let currentChapter: Int?
    let totalChapters: Int?
}

struct MangaReadingProgressController {

    // MARK: - Draft

    func editorDraft(
        for item: MyListCollectionItem,
        manga: MangaDetailDTO
    ) -> MangaReadingProgressEditorDraft {
        MangaReadingProgressEditorDraft(
            item: item,
            totalChapters: totalChapters(for: manga)
        )
    }

    // MARK: - Progress Update

    func incrementUpdate(
        for item: MyListCollectionItem,
        manga: MangaDetailDTO
    ) -> MangaReadingProgressUpdate {
        let resolvedTotalChapters = totalChapters(for: manga)
        let nextChapter = min(
            (item.currentChapter ?? 0) + 1,
            resolvedTotalChapters ?? Int.max
        )
        let nextStatus: MangaReadingStatus
        if let resolvedTotalChapters, nextChapter >= resolvedTotalChapters {
            nextStatus = .completed
        } else {
            nextStatus = .reading
        }

        return MangaReadingProgressUpdate(
            status: nextStatus,
            currentChapter: nextChapter,
            totalChapters: resolvedTotalChapters
        )
    }

    func decrementUpdate(
        for item: MyListCollectionItem,
        manga: MangaDetailDTO
    ) -> MangaReadingProgressUpdate {
        let resolvedTotalChapters = totalChapters(for: manga)
        let nextChapter = max((item.currentChapter ?? 0) - 1, 0)
        let nextStatus: MangaReadingStatus = nextChapter > 0 ? .reading : .planned

        return MangaReadingProgressUpdate(
            status: nextStatus,
            currentChapter: nextChapter,
            totalChapters: resolvedTotalChapters
        )
    }

    // MARK: - Private Methods

    private func totalChapters(for manga: MangaDetailDTO) -> Int? {
        guard let chapters = manga.chapters, chapters > 0 else { return nil }
        return chapters
    }
}
