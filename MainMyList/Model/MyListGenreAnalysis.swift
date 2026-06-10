//
//  MyListGenreAnalysis.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import Foundation

struct MyListGenreAnalysis: Identifiable {
    let scope: MyListStatisticsScope
    let itemCount: Int
    let genreSlices: [MyListGenreSlice]
    let missingGenreItemCount: Int

    var id: MyListStatisticsScope { scope }
    var topGenreSlice: MyListGenreSlice? { genreSlices.first }
}
