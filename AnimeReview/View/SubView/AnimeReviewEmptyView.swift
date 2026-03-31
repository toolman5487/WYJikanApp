//
//  AnimeReviewEmptyView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

import SwiftUI

struct AnimeReviewEmptyView: View {
    var body: some View {
        Text("尚無評論")
            .font(.body)
            .foregroundStyle(ThemeColor.textSecondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
