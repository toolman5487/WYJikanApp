//
//  MainSearchListSkeletonView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/4.
//

import SwiftUI

struct MainSearchListSkeletonView: View {

    // MARK: - Properties

    private static let rowCount = 8

    // MARK: - Body

    var body: some View {
        List {
            ForEach(0..<Self.rowCount, id: \.self) { _ in
                MainSearchRowSkeletonView()
                    .listRowSeparator(.visible)
            }
        }
        .listStyle(.plain)
        .scrollDisabled(true)
    }
}

struct MainSearchRowSkeletonView: View {

    // MARK: - Body

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(.systemGray5))
                .frame(width: 48, height: 64)
                .overlay {
                    ShimmerView()
                }
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                SkeletonBar(width: nil, height: 16, cornerRadius: 4)
                SkeletonBar(width: 180, height: 12, cornerRadius: 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}
