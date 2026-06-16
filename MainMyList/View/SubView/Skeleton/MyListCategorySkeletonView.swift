//
//  MyListCategorySkeletonView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/21.
//

import SwiftUI

struct MyListCategorySkeletonView: View {

    // MARK: - Properties

    private let chipWidths: [CGFloat] = [74, 74, 72, 72]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            MyListSectionHeaderSkeletonView(titleWidth: 96, subtitleWidth: 132)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(chipWidths.enumerated()), id: \.offset) { _, width in
                        SkeletonBar(width: width, height: 40, cornerRadius: 20)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    MyListCategorySkeletonView()
        .padding()
}
