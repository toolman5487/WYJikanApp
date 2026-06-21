//
//  MyListGenreSlice.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import Foundation

nonisolated struct MyListGenreSlice: Identifiable, Sendable {
    let genreName: String
    let count: Int

    var id: String { genreName }
}
