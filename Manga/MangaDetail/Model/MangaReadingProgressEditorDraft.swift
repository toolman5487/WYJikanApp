//
//  MangaReadingProgressEditorDraft.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/6/11.
//

import Foundation

struct MangaReadingProgressEditorDraft: Identifiable {
    let id = UUID()
    let totalChapters: Int?
    var status: MangaReadingStatus
    var currentChapter: Int

    init(
        item: MyListCollectionItem,
        totalChapters: Int?
    ) {
        self.totalChapters = totalChapters ?? item.totalChaptersSnapshot
        self.status = item.mangaReadingStatus
        self.currentChapter = item.currentChapter ?? 0
    }
}
