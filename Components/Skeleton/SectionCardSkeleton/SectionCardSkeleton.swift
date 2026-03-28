//
//  SectionCardSkeleton.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/28.
//

import SwiftUI

struct SectionCardSkeleton: View {
    let titleWidth: CGFloat
    let rowCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SkeletonBar(width: titleWidth, height: 22, cornerRadius: 6)

            VStack(spacing: 10) {
                ForEach(0..<rowCount, id: \.self) { _ in
                    HStack(alignment: .top, spacing: 12) {
                        SkeletonBar(width: 72, height: 16, cornerRadius: 4)
                        SkeletonBar(width: nil, height: 16, cornerRadius: 4)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
