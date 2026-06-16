//
//  MyListSummarySkeletonView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/21.
//

import SwiftUI

struct MyListSummarySkeletonView: View {

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            MyListSectionHeaderSkeletonView(titleWidth: 120, subtitleWidth: 156)

            HStack(spacing: 12) {
                MyListSummaryCardSkeletonView()
                MyListSummaryCardSkeletonView()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - MyListSummaryCardSkeletonView

private struct MyListSummaryCardSkeletonView: View {

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 32, height: 32)
                .overlay {
                    ShimmerView()
                }

            SkeletonBar(width: 72, height: 24, cornerRadius: 8)
            SkeletonBar(width: 104, height: 12, cornerRadius: 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

#Preview {
    MyListSummarySkeletonView()
        .padding()
}
