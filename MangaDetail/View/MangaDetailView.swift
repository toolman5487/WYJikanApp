//
//  MangaDetailView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

import SwiftUI

struct MangaDetailView: View {

    let malId: Int

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 44))
                .foregroundStyle(ThemeColor.textTertiary)
            Text("漫畫詳情")
                .font(.title3.weight(.semibold))
                .foregroundStyle(ThemeColor.textPrimary)
        }
        .id(malId)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("漫畫")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        MangaDetailView(malId: 1)
    }
}
