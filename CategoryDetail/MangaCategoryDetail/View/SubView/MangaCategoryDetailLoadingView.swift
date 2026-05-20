//
//  MangaCategoryDetailLoadingView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/2.
//

import SwiftUI

struct MangaCategoryDetailLoadingView: View {

    // MARK: - Properties

    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                SkeletonBar(width: 148, height: 24, cornerRadius: 8)
                SkeletonBar(width: 220, height: 16, cornerRadius: 8)
            }

            LazyVGrid(columns: gridColumns, spacing: 20) {
                ForEach(0..<4, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 12) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.systemGray5))
                            .frame(height: 220)

                        SkeletonBar(width: 120, height: 16, cornerRadius: 8)
                        SkeletonBar(width: 84, height: 12, cornerRadius: 8)
                    }
                }
            }
        }
    }
}
