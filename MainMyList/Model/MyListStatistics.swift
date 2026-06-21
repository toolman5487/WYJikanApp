//
//  MyListStatistics.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import Foundation

nonisolated struct MyListStatistics: Sendable {
    let totalCount: Int
    let animeCount: Int
    let mangaCount: Int
    let allAnalysis: MyListGenreAnalysis
    let animeAnalysis: MyListGenreAnalysis
    let mangaAnalysis: MyListGenreAnalysis
    let selectedAnalysis: MyListGenreAnalysis
    let formatAnalysis: MyListFormatAnalysis
}
