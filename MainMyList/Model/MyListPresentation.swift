//
//  MyListPresentation.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import Foundation

nonisolated struct MyListPresentation: Sendable {
    let filteredItems: [MyListItemSnapshot]
    let genreSections: [MyListGenreCollectionSection]
    let formatSections: [MyListFormatCollectionSection]
    let statistics: MyListStatistics
    let summaryTile: MyListSummaryContent
    let animeWatchStatusSummary: AnimeWatchStatusSummary
    let mangaReadingStatusSummary: MangaReadingStatusSummary
}
