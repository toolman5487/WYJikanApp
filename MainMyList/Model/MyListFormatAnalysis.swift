//
//  MyListFormatAnalysis.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import Foundation

struct MyListFormatAnalysis {
    let scope: MyListStatisticsScope
    let itemCount: Int
    let formatSlices: [MyListFormatSlice]
    let missingTypeItemCount: Int

    var topFormatSlice: MyListFormatSlice? { formatSlices.first }
}
