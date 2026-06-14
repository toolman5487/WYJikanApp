//
//  MyListPresentation.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import Foundation

struct MyListPresentation {
    let filteredItems: [MyListCollectionItem]
    let genreSections: [MyListGenreCollectionSection]
    let formatSections: [MyListFormatCollectionSection]
    let statistics: MyListStatistics
    let summaryTile: MyListSummaryContent
    let mangaReadingStatusSummary: MangaReadingStatusSummary
}
