//
//  MyListCategorySkeletonView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/21.
//

import SwiftUI

struct MyListCategorySkeletonView: View {
    private let chipWidths: [CGFloat] = [74, 74, 72, 72]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MyListSectionHeaderSkeletonView(titleWidth: 96, subtitleWidth: 132)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(chipWidths.enumerated()), id: \.offset) { _, width in
                        SkeletonBar(width: width, height: 38, cornerRadius: 19)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    MyListCategorySkeletonView()
        .padding()
}
