//
//  AnimeReviewSkeletonViews.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

import SwiftUI

// MARK: - List

struct AnimeReviewListSkeletonView: View {

    private static let rowCount = 6

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(0..<Self.rowCount, id: \.self) { index in
                    if index > 0 {
                        Divider()
                    }
                    AnimeReviewRowSkeletonView()
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Row

struct AnimeReviewRowSkeletonView: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerPlaceholder
            tagsPlaceholder
            bodyPlaceholder
            buttonPlaceholder
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Private

    private var headerPlaceholder: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 44, height: 44)
                .overlay {
                    ShimmerView()
                }
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                SkeletonBar(width: 140, height: 16, cornerRadius: 8)
                SkeletonBar(width: 96, height: 12, cornerRadius: 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            SkeletonBar(width: 40, height: 24, cornerRadius: 8)
        }
    }

    private var tagsPlaceholder: some View {
        HStack(spacing: 12) {
            SkeletonBar(width: 72, height: 36, cornerRadius: 16)
            SkeletonBar(width: 96, height: 36, cornerRadius: 16)
            SkeletonBar(width: 64, height: 36, cornerRadius: 16)
        }
    }

    private var bodyPlaceholder: some View {
        VStack(alignment: .leading, spacing: 8) {
            SkeletonBar(width: nil, height: 16, cornerRadius: 4)
            SkeletonBar(width: 160, height: 16, cornerRadius: 4)
        }
    }

    private var buttonPlaceholder: some View {
        SkeletonBar(width: nil, height: 44, cornerRadius: 12)
    }
}

#Preview("List") {
    AnimeReviewListSkeletonView()
}

#Preview("Row") {
    ScrollView {
        AnimeReviewRowSkeletonView()
            .padding()
    }
}
