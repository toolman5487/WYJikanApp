//
//  SectionCardSkeleton.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/28.
//

import SwiftUI

struct SectionCardSkeleton: View {
    let rowCount: Int

    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(.systemGray5))
            .frame(maxWidth: .infinity)
            .frame(height: sectionHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sectionHeight: CGFloat {
        let verticalSpacing: CGFloat = 10
        let rowHeight: CGFloat = 20
        let contentPadding: CGFloat = 24
        return CGFloat(rowCount) * rowHeight + CGFloat(max(0, rowCount - 1)) * verticalSpacing + contentPadding
    }
}
