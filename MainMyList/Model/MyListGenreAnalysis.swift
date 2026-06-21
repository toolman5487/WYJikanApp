//
//  MyListGenreAnalysis.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import Foundation

nonisolated struct MyListGenreAnalysis: Identifiable, Sendable {
    let scope: MyListStatisticsScope
    let itemCount: Int
    let genreSlices: [MyListGenreSlice]
    let missingGenreItemCount: Int

    var id: MyListStatisticsScope { scope }
    var topGenreSlice: MyListGenreSlice? { genreSlices.first }
}
