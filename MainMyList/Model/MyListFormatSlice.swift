//
//  MyListFormatSlice.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import Foundation

struct MyListFormatSlice: Identifiable {
    let title: String
    let iconName: String
    let count: Int

    var id: String { title }
}
