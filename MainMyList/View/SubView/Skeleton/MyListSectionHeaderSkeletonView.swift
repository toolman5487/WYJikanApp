//
//  MyListSectionHeaderSkeletonView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/21.
//

import SwiftUI

struct MyListSectionHeaderSkeletonView: View {
    let titleWidth: CGFloat
    let subtitleWidth: CGFloat

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 8) {
                SkeletonBar(width: titleWidth, height: 20, cornerRadius: 8)
                SkeletonBar(width: subtitleWidth, height: 12, cornerRadius: 4)
            }

            Spacer()

            SkeletonBar(width: 48, height: 16, cornerRadius: 4)
        }
    }
}

#Preview {
    MyListSectionHeaderSkeletonView(titleWidth: 112, subtitleWidth: 188)
        .padding()
}
