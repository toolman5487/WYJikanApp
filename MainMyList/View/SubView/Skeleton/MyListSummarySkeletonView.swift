//
//  MyListSummarySkeletonView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/21.
//

import SwiftUI

struct MyListSummarySkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MyListSectionHeaderSkeletonView(titleWidth: 120, subtitleWidth: 156)

            HStack(spacing: 12) {
                MyListSummaryCardSkeletonView()
                MyListSummaryCardSkeletonView()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MyListSummaryCardSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 34, height: 34)
                .overlay {
                    ShimmerView()
                }

            SkeletonBar(width: 74, height: 24, cornerRadius: 7)
            SkeletonBar(width: 104, height: 13, cornerRadius: 5)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

#Preview {
    MyListSummarySkeletonView()
        .padding()
}
